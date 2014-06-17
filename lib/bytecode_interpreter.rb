UNNAMED_BLOCK = '__block__'

if RUBY_PLATFORM == 'opal'
  def gets
  end

  def puts *args
    if args.size > 0
      $stdout.write args.map { |arg|
        arg_to_s = "#{arg}"
        arg_to_s + (arg_to_s.end_with?("\n") ? "" : "\n")
      }.join
    else
      $stdout.write "\n"
    end
  end

  def p *args
    args.each do |arg|
      $stdout.write arg.inspect + "\n"
    end
    case args.size
      when 0 then nil
      when 1 then args[0]
      else args
    end
  end
end

$console_texts = []
$is_capturing_output = false
class <<$stdout
  alias :old_write :write
  def write *args
    if $is_capturing_output
      $console_texts = $console_texts.clone +
        args.map { |arg| [:stdout, "#{arg}"] }
    else
      old_write *args
    end
  end
end
class <<$stderr
  alias :old_write :write
  def write *args
    if $is_capturing_output
      $console_texts = $console_texts.clone +
        args.map { |arg| [:stderr, "#{arg}"] }
    else
      old_write *args
    end
  end
end

class String
  def <<(*args)
    self + args.map { |arg| "#{arg}" }.join
  end
end

class ProgramTerminated < RuntimeError
  attr_reader :cause
  def initialize(cause)
    @cause = cause
  end
end

class BytecodeInterpreter
  def initialize
    @partial_calls = []
    @num_partial_call_executing = nil
    @result = [] # a stack with 0 or 1 items in it
    @vars_stack = [{}]
    @started_var_names = []
    @main = (RUBY_PLATFORM == 'opal') ?
      `Opal.top` : TOPLEVEL_BINDING.eval('self')
    @accepting_input = false
    @accepted_input = nil
    @rescue_labels = [] # list of [label, stack_size1, stack_size2] tuples
      # stack_size1 is with counting pop_next_one_too_on_return
      # stack_size2 is when you don't count pop_next_one_too_on_return
    # path, method, line, col, pop_next_one_too_on_return
    @method_stack = [['Runtime', '<main>', nil, nil, false]]
    $console_texts = []
    begin raise ''; rescue; end # set $! to RuntimeError.new('')
  end

  def visible_state
    {
      partial_calls: @partial_calls.map { |call| call.clone },
      started_var_names: @started_var_names,
      vars: @vars_stack.last.inject({}) { |accum, pair|
        key, value = pair
        accum[key] = value[0] # undo the array wrapping
        accum
      },
      output: $console_texts,
      num_partial_call_executing: @num_partial_call_executing,
      accepting_input: @accepting_input,
    }
  end

  def is_accepting_input?
    @accepting_input
  end

  def interpret bytecode #, speed, stdin
    case bytecode[0]
      when :position
        @method_stack.last[0] = bytecode[1] # path
        @method_stack.last[2] = bytecode[2] # line
        @method_stack.last[3] = bytecode[3] # col
        nil
      when :token
        @method_stack.last[2] = bytecode[1] # line
        @method_stack.last[3] = bytecode[2] # col
        nil
      when :result
        case bytecode[1]
          when Array then result_is bytecode[1].clone
          when Hash  then result_is bytecode[1].clone
          else result_is bytecode[1]
        end
        nil
      when :discard
        pop_result
        nil
      when :start_call
        @partial_calls.push []
        nil
      when :top
        result_is @main
        nil
      when :arg
        result = pop_result
        @partial_calls.last.push result
        nil
      when :make_proc
        result = Proc.new { |*args| ['RedirectMethod', bytecode[1]] }
        result.instance_variable_set '@env', @vars_stack.last
        result.instance_variable_set '@defined_in', @method_stack.last
        result.instance_variable_set '@is_yield', false
        result_is result
        nil
      when :pre_call
        @num_partial_call_executing = @partial_calls.size - 1
        if @partial_calls.last == [@main, :gets, nil]
          @accepting_input = true
        end
        nil
      when :call
        @num_partial_call_executing = nil
        call = @partial_calls.last
        if @accepted_input != nil
          result_is @accepted_input
          @accepted_input = nil
          @partial_calls.pop
          nil
        else
          result = do_call *call
          if Array === result && result[0] == 'RedirectMethod'
            ['GOSUB', result[1]]
            # @method_stack.pop will be called by will_return
          elsif Array === result && result[0] == 'RESCUE'
            result_is nil
            @partial_calls.pop
            result
            # @method_stack.pop will be called by will_return
          else
            result_is result
            @partial_calls.pop
            nil
          end
        end
      when :return
        @partial_calls.pop
        @vars_stack.pop
        _, _, _, _, pop_next_method_too = @method_stack.pop
        if pop_next_method_too
          @vars_stack.pop
          @method_stack.pop
        end
        ['RETURN']
      when :start_var
        @started_var_names.push bytecode[1]
        nil
      when :to_var
        var_name = bytecode[1]
        @started_var_names = @started_var_names - [var_name]
        value = pop_result
        # store vars in arrays, so closures can modify their values
        if @vars_stack.last.has_key? var_name
          @vars_stack.last[var_name][0] = value
        else
          @vars_stack.last[var_name] = [value]
        end
        result_is value
        nil
      when :to_vars
        _, splat_num, block_num, *var_names = bytecode
        array = pop_result
        old_array = array.clone

        @started_var_names = @started_var_names - var_names

        if Proc === array.last
          @vars_stack.last[UNNAMED_BLOCK] = [array.pop]
        end
        var_names.each_with_index do |var_name, i|
          if i == splat_num
            value = array
          elsif i == block_num
            value = @vars_stack.last[UNNAMED_BLOCK][0]
          else
            value = array.shift
          end
          # store vars in arrays, so closures can modify their values
          if @vars_stack.last.has_key? var_name
            @vars_stack.last[var_name][0] = value
          else
            @vars_stack.last[var_name] = [value]
          end
        end
        if @vars_stack.last[UNNAMED_BLOCK]
          # clone the block so we can tell the difference between yield
          # (translated to __block__.call) and b.call, if param is named &b
          old = @vars_stack.last[UNNAMED_BLOCK][0]
          new = Proc.new { |*args| old.call *args }
          new.instance_variable_set '@env', old.instance_variable_get('@env')
          new.instance_variable_set '@defined_in',
            old.instance_variable_get('@defined_in')
          new.instance_variable_set '@is_yield', true
          @vars_stack.last[UNNAMED_BLOCK][0] = new
        end
        result_is old_array
        nil
      when :from_var
        var_name = bytecode[1]
        if @vars_stack.last.has_key? var_name
          out = @vars_stack.last[var_name][0] # in array so closures can modify
          result_is out
        else
          raise "Looking up unset variable #{var_name}"
        end
        nil
      when :make_symbol
        result = pop_result
        `result.is_symbol = true;` if RUBY_PLATFORM == 'opal'
        result_is result
        nil
      when :goto
        ['GOTO', bytecode[1]]
      when :goto_if_not
        result = pop_result
        if !result
          ['GOTO', bytecode[1]]
        else
          nil
        end
      when :args
        _, min_num_args, max_num_args = bytecode
        block = @partial_calls.last[2]
        args = @partial_calls.last[3..-1]
        result_is args + (block ? [block] : [])

        if (min_num_args && args.size < min_num_args) ||
           (max_num_args && args.size > max_num_args)
          num_expected =
            if max_num_args.nil? then "#{min_num_args}+"
            elsif min_num_args == max_num_args then min_num_args
            else "#{min_num_args}..#{max_num_args}"
            end
          message =
            "wrong number of arguments (#{args.size} for #{num_expected})"
          raise_exception { raise ArgumentError.new(message) }
        end
        nil
      when :vars_from_env_except
        var_names = bytecode[1..-1]
        if Proc === @partial_calls.last[0]
          env = @partial_calls.last[0].instance_variable_get '@env'
          env.keys.each do |var_name|
            if !var_names.include?(var_name)
              @vars_stack.last[var_name] = env[var_name]
            end
          end
        else
          new_vars = {}
        end
        nil
      when :goto_param_defaults
        num_args = @partial_calls.last.size - 3
        if 1 + num_args >= bytecode.size
          label = bytecode.last
        else
          label = bytecode[1 + (num_args)]
        end
        ['GOTO', label]
      when :push_rescue
        # save the stack size so we can easily remove any additional methods
        stack_size1 = @method_stack.size
        stack_size2 = @method_stack.count { |m| !m[4] }
        @rescue_labels.push [bytecode[1], stack_size1, stack_size2]
        nil
      when :pop_rescue
        label, _ = @rescue_labels.pop
        if label != bytecode[1]
          raise "Expected to pop #{bytecode[1]} but was #{label}"
        end
        nil
      when :to_gvar
        var_name = bytecode[1]
        value = pop_result
        eval "#{var_name} = value"
        result_is value
        nil
      when :from_gvar
        var_name = bytecode[1]
        if var_name.to_s == '$!'
          out = $! || $bang
        else
          out = eval var_name.to_s
        end
        result_is out
        nil
      when :const
        result_is Module.const_get(bytecode[1])
        nil
      when :clear_dollar_bang
        # we extend $! so it's accesible from user code's rescue blocks,
        # even though we rescued the exception in our Opal code.
        # but don't extend $! forever; it should be nil after the user code's
        # rescue blocks end.
        $bang = nil
        nil
    end
  end

  def set_input text
    @accepted_input = text
    @accepting_input = false
    if false # don't automatically show inputted text; can be confused with output
      $console_texts = $console_texts.clone + [[:stdin, text]]
    end
  end

  def get_stdout
    stdout_pairs = $console_texts.select { |pair| pair[0] == :stdout }
    stdout_pairs.map { |pair| pair[1] }.join
  end

  def get_stderr
    stderr_pairs = $console_texts.select { |pair| pair[0] == :stderr }
    stderr_pairs.map { |pair| pair[1] }.join
  end

  def get_stdout_and_stderr
    $console_texts.select { |pair| pair[0] == :stdout || pair[0] == :stderr }
  end

  private

  def result_is new_result
    # use boxed JavaScript objects not primitives, so we can look up their
    # object_id, at least for strings. Maybe override number and bool's
    # object_id to be constant, like MRI's, later.
    if RUBY_PLATFORM == 'opal'
      `if (typeof(new_result) === 'number') {
        new_result = new Number(new_result);
      } else if (typeof(new_result) === 'string') {
        new_result = new String(new_result);
      } else if (typeof(new_result) === 'boolean') {
        new_result = new Boolean(new_result);
      }`
    end
    @result.push new_result
    raise "Result stack has too many items: #{@result}" if @result.size > 1
  end

  # since :args bytecode looks at partial_calls to determine what the
  # args were, it's not enough just to call the right method; we have
  # to setup partial_calls with arguments that the runtime expects.
  def simulate_call_to receiver, new_method_name, *args, &proc_
    entry = @method_stack.pop
    @method_stack.push [entry[0], new_method_name, nil, nil, false]
    @partial_calls.pop
    @partial_calls.push [receiver, new_method_name, proc_, *args]
    receiver.public_send new_method_name, *args
  end

  def do_call receiver, method_name, proc_, *args
    path, _, line_num = @method_stack.last
    @method_stack.push [path, method_name, line_num, nil, false]
    @vars_stack.push({})
    begin
      result = \
      if Array === receiver && %w[collect each each_index keep_if map map!
          reject select select!].include?(method_name.to_s)
        new_method_name = case method_name
          when :collect    then :__array_map # same as map
          when :each       then :__array_each
          when :each_index then :__array_each_index
          when :keep_if    then :__array_keep_if
          when :map        then :__array_map
          when :map!       then :__array_map!
          when :reject     then :__array_reject
          when :select     then :__array_select
          when :select!    then :__array_select!
        end
        simulate_call_to @main, new_method_name, @partial_calls.last[0], &proc_

      elsif method_name == :define_method
        if RUBY_PLATFORM == 'opal'
          `Opal.defs(receiver, '$' + args[0], proc_);`
          result = nil
        else
          result = @main.send method_name, *args, &proc_
        end

      elsif method_name == :send
        new_method_name = args.shift
        result = simulate_call_to receiver, new_method_name, *args, &proc_

      elsif Proc === receiver && method_name == :call
        is_yield = receiver.instance_variable_get('@is_yield')
        if is_yield
          # discard the .call stack entry, because the user didn't write that
          @method_stack.pop
          @vars_stack.pop
        end
        path, method = receiver.instance_variable_get('@defined_in')
        @method_stack.push [path, "block in #{method}", nil, nil, !is_yield]
        @vars_stack.push({})
        result = receiver.public_send method_name, *args, &proc_

      elsif receiver == @main
        begin
          $is_capturing_output = true
          result = @main.send method_name, *args, &proc_
          $is_capturing_output = false
          result
        rescue NoMethodError => e
          if args.size == 0 &&
             e.message == "undefined method `#{method_name}' for main"
            raise NameError.new "undefined local variable or method " +
              "`#{method_name}' for main:Object"
          else
            raise e
          end
        end

      else
        $is_capturing_output = true
        result = receiver.public_send method_name, *args, &proc_
        $is_capturing_output = false
        result
      end

      if Array === result && result[0] == 'RedirectMethod'
        # don't pop
      else
        @method_stack.pop
        @vars_stack.pop
      end
      result
    rescue Exception => e
      $is_capturing_output = false
      # don't call @method_stack.pop; exception handler will deal with it

      # It's necessary to write "return" here because of an Opal bug where
      # only the first rescue gets return like it should.
      return handle_exception(e)
    end
  end

  def raise_exception(&block)
    begin
      yield
    rescue => e
      handle_exception e
    end
  end

  def handle_exception e
    # take off the last entry (which is the backtrace call itself)
    # then sort with newer calls at top
    e.instance_variable_set :@backtrace,
      @method_stack[0...-1].reverse.map { |entry|
        sprintf("%s:%s:in `%s'", entry[0], entry[2], entry[1])
      }
    def e.backtrace
      @backtrace
    end

    if @rescue_labels.size > 0
      label, target_stack_size1, target_stack_size2 = @rescue_labels.pop
      while @method_stack.size > target_stack_size1
        @method_stack.pop
        @vars_stack.pop
      end
      # $! gets set to nil after our rescue ends, but we'll want it defined
      # until the *user*'s rescue ends
      $bang = $!
      ['RESCUE', label, target_stack_size2]
    else
      text = "#{e.class}: #{e.message}\n" + e.backtrace.map { |entry|
        "  #{entry}" }.join("\n")
      $console_texts = $console_texts.clone + [[:stderr, text]]
      raise ProgramTerminated.new e
    end
  end

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end

  def self.RUNTIME_PRELUDE
    <<EOF
def __array_each array
  i = 0
  n = array.size
  while i < n
    yield array[i]
    i += 1
  end
  array
end
def __array_each_index array
  i = 0
  n = array.size
  while i < n
    yield i
    i += 1
  end
  array
end
def __array_keep_if array
  i = 0
  n = array.size
  while i < n
    if !(yield array[i])
      array.slice! i
      i -= 1
      n -= 1
    end
    i += 1
  end
  array
end
def __array_map array
  i = 0
  n = array.size
  out = []
  while i < n
    out.push yield array[i]
    i += 1
  end
  out
end
def __array_map! array
  i = 0
  n = array.size
  while i < n
    array[i] = yield array[i]
    i += 1
  end
  array
end
def __array_reject array
  i = 0
  n = array.size
  out = []
  while i < n
    if !(yield array[i])
      out.push array[i]
    end
    i += 1
  end
  out
end
def __array_select array
  i = 0
  n = array.size
  out = []
  while i < n
    if yield array[i]
      out.push array[i]
    end
    i += 1
  end
  out
end
def __array_select! array
  i = 0
  n = array.size
  changed = false
  while i < n
    if !(yield array[i])
      array.slice! i
      i -= 1
      n -= 1
      changed = true
    end
    i += 1
  end
  changed ? array : nil
end
def assert_equal a, b
  if b != a
    raise "Expected \#{a.inspect} but got \#{b.inspect}"
  end
end
def __run_test test_name
  begin
    send test_name
    puts "\#{test_name} PASSED"
  rescue RuntimeError => e
    puts "\#{test_name} FAILED"
    $stderr.write "\#{e}\\n"
    e.backtrace[0...-2].each do |line|
      $stderr.puts "  \#{line}\\n"
    end
  end
end
EOF
  end
end
