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
$is_capturing_stdout = false
class <<$stdout
  alias :old_write :write
  def write *args
    if $is_capturing_stdout
      $console_texts = $console_texts.clone + args.map { |arg| [:stdout, "#{arg}"] }
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
    @gosubbing_label = nil
    @gotoing_label = nil
    @last_token_pos = nil
    @rescue_labels = [] # list of [label, stack.size] tuples
    @method_stack = [['path', '<main>', nil, nil]] # path, method, line, col

    $console_texts = []
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

  def is_result_truthy?
    @result[0] && !!@result[0]
  end

  def is_accepting_input?
    @accepting_input
  end

  def interpret bytecode #, speed, stdin
    @gosubbing_label = nil
    @gotoing_label = nil
    case bytecode[0]
      when :token
        @method_stack.last[2] = bytecode[1] # line
        @method_stack.last[3] = bytecode[2] # col
      when :result
        result_is bytecode[1]
      when :discard
        pop_result
      when :start_call
        @partial_calls.push []
      when :top
        result_is @main
      when :arg
        result = pop_result
        @partial_calls.last.push result
      when :make_proc
        result = Proc.new { |*args| ['RedirectMethod', bytecode[1]] }
        result.instance_variable_set '@env', @vars_stack.last
        result_is result
      when :pre_call
        @num_partial_call_executing = @partial_calls.size - 1
        if @partial_calls.last == [@main, :gets, nil]
          @accepting_input = true
        end
      when :call
        @num_partial_call_executing = nil
        call = @partial_calls.last
        if @accepted_input != nil
          result_is @accepted_input
          @accepted_input = nil
          @partial_calls.pop
        else
          result = do_call *call
          if Array === result && result[0] == 'RedirectMethod'
            @gosubbing_label = result[1]
            # @method_stack.pop will be called by will_return
          else
            result_is result
            @partial_calls.pop
          end
        end
      when :will_return
        @partial_calls.pop
        @vars_stack.pop
        @method_stack.pop
      when :start_var
        @started_var_names.push bytecode[1]
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
        result_is old_array
      when :from_var
        var_name = bytecode[1]
        if @vars_stack.last.has_key? var_name
          out = @vars_stack.last[var_name][0] # in array so closures can modify
          result_is out
        else
          raise "Looking up unset variable #{var_name}"
        end
      when :make_symbol
        result = pop_result
        `result.is_symbol = true;` if RUBY_PLATFORM == 'opal'
        result_is result
      when :goto_if_not
        pop_result
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
      when :goto_param_defaults
        num_args = @partial_calls.last.size - 3
        if 1 + num_args >= bytecode.size
          label = bytecode.last
        else
          label = bytecode[1 + (num_args)]
        end
        @gotoing_label = label
      when :push_rescue
        # save the stack size so we can easily remove any additional methods
        @rescue_labels.push [bytecode[1], @method_stack.size]
      when :pop_rescue
        label, _ = @rescue_labels.pop
        if label != bytecode[1]
          raise "Expected to pop #{bytecode[1]} but was #{label}"
        end
      when :to_gvar
        var_name = bytecode[1]
        value = pop_result
        eval "#{var_name} = value"
        result_is value
      when :from_gvar
        var_name = bytecode[1]
        if var_name.to_s == '$!'
          out = $! || $bang
        else
          out = eval var_name.to_s
        end
        result_is out
      when :const
        result_is Module.const_get(bytecode[1])
      when :clear_dollar_bang
        # we extend $! so it's accesible from user code's rescue blocks,
        # even though we rescued the exception in our Opal code.
        # but don't extend $! forever; it should be nil after the user code's
        # rescue blocks end.
        $bang = nil
    end
    nil
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

  def gosubbing_label
    @gosubbing_label
  end

  def gotoing_label
    @gotoing_label
  end

  def stack_size
    @method_stack.size
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
  def simulate_call_to method_name, *args, &proc_
    @partial_calls.pop
    @partial_calls.push [@main, :__array_each, proc_, *args]
    @main.public_send method_name, *args
  end

  def do_call receiver, method_name, proc_, *args
    @method_stack.push ['path', method_name, nil, nil]
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
        simulate_call_to new_method_name, @partial_calls.last[0], &proc_

      elsif method_name == :define_method
        if RUBY_PLATFORM == 'opal'
          `Opal.defs(receiver, '$' + args[0], proc_);`
          result = nil
        else
          result = @main.send method_name, *args, &proc_
        end

      elsif receiver == @main && method_name == :raise && args.size == 0 &&
            $! == nil
        # Work around for Opal bug: calling raise with no arguments when
        # $! is nil raises an uncatchable exception :-/
        args = [RuntimeError, '']
        result = @main.send method_name, *args, &proc_

      elsif receiver == @main
        begin
          $is_capturing_stdout = true
          result = @main.send method_name, *args, &proc_
          $is_capturing_stdout = false
          result
        rescue NoMethodError => e
          if args.size == 0
            raise NameError.new "undefined local variable or method " +
              "`#{method_name}' for main:Object"
          else
            raise e
          end
        end

      else
        $is_capturing_stdout = true
        result = receiver.public_send method_name, *args, &proc_
        $is_capturing_stdout = false
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
      $is_capturing_stdout = false
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
      @gotoing_label, target_stack_size = @rescue_labels.pop
      while @method_stack.size > target_stack_size
        @method_stack.pop
        @vars_stack.pop
      end
      # $! gets set to nil after our rescue ends, but we'll want it defined
      # until the *user*'s rescue ends
      $bang = $!
    else
      text = "#{e.class}: #{e.message}\n" + e.backtrace.map { |entry|
        "\t#{entry}" }.join("\n")
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
def __run_tests
  test_names = methods.select { |m| m.start_with?('test') }
  test_names.each do |test_name|
    begin
      method(test_name).call
      puts "\#{test_name} PASSED"
    rescue RuntimeError => e
      p e.backtrace
      puts "\#{test_name} FAILED"
    end
  end
end
EOF
  end
end
