if RUBY_PLATFORM == 'opal'
  def gets
    `window.$stdin_is_waiting = true;`
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
end

class NewProc
  attr_accessor :label, :env, :param_names
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
        @last_token_pos = [bytecode[1], bytecode[2]]
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
        result = NewProc.new
        result.label = bytecode[1]
        result.env = @vars_stack.last
        result_is result
      when :pre_call
        @num_partial_call_executing = @partial_calls.size - 1
        if @partial_calls.last == [@main, :gets]
          @accepting_input = true
        elsif NewProc === @partial_calls.last[0] &&
              @partial_calls.last[1] == :call
          proc_ = @partial_calls.last[0]
          @gosubbing_label = proc_.label
        end
      when :call
        @num_partial_call_executing = nil
        call = @partial_calls.pop
        if @accepted_input != nil
          result_is @accepted_input
          @accepted_input = nil
        elsif NewProc === call[0] && call[1] == :call
          # we've now returned from calling the proc; result is already set
          @vars_stack.pop
        else
          begin
            result_is do_call *call
          rescue
            result_is nil
            raise
          end
        end
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
        array = pop_result
        old_array = array.clone
        splat_num = bytecode[1]
        var_names = bytecode[2..-1]
        @started_var_names = @started_var_names - var_names
        var_names.each_with_index do |var_name, i|
          if i == splat_num
            value = array
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
        args = @partial_calls.last[3..-1]
        result_is args
      when :vars_from_env_except
        var_names = bytecode[1..-1]
        if NewProc === @partial_calls.last[0]
          new_vars = @partial_calls.last[0].env.reject do |var_name|
            var_names.include?(var_name)
          end
        else
          new_vars = {}
        end
        @vars_stack.push new_vars
      when :goto_param_defaults
        num_args = @partial_calls.last.size - 3
        if 1 + num_args >= bytecode.size
          label = bytecode.last
        else
          label = bytecode[1 + (num_args)]
        end
        @gotoing_label = label
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

  def do_call receiver, method_name, proc_, *args
    begin
      if proc_
        if receiver == @main && method_name == :lambda
          proc_
        else
          raise Exception.new "Basic Ruby doesn't support the calling of
            arbitrary methods with blocks"
        end
      elsif receiver == @main
        begin
          $is_capturing_stdout = true
          result = @main.send method_name, *args
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
        result = receiver.public_send(method_name, *args)
        $is_capturing_stdout = false
        result
      end
    rescue Exception => e
      $is_capturing_stdout = false
      text = "#{e.class}: #{e.message}#{error_position}\n"
      $console_texts = $console_texts.clone + [[:stderr, text]]
      raise ProgramTerminated.new text
    end
  end

  def error_position
    return '' if @last_token_pos.nil?
    " at line #{@last_token_pos[0]}"
    # " at line #{@last_token_pos[0]} column #{@last_token_pos[1]}"
  end

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end
end
