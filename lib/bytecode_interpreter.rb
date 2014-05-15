if RUBY_PLATFORM == 'opal'
  def gets
    `window.$stdin_is_waiting = true;`
  end
end

$captured_stdout = []
$is_capturing_stdout = false
class <<$stdout
  alias :old_write :write
  def write *args
    if $is_capturing_stdout
      if RUBY_PLATFORM == 'opal'
        $captured_stdout = $captured_stdout.clone +
          args.map { |arg| "#{arg}\n" }
      else
        $captured_stdout = $captured_stdout.clone + args.map { |arg| "#{arg}" }
      end
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

class BytecodeInterpreter
  def initialize
    @partial_calls = []
    @num_partial_call_executing = nil
    @result = [] # a stack with 0 or 1 items in it
    @vars = {}
    @started_var_names = []
    @main = (RUBY_PLATFORM == 'opal') ?
      `Opal.top` : TOPLEVEL_BINDING.eval('self')
    @accepting_input = false
    @accepted_input = nil

    $captured_stdout = []
  end

  def visible_state
    {
      partial_calls: @partial_calls.map { |call| call.clone },
      started_var_names: @started_var_names,
      vars: @vars,
      output: $captured_stdout,
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
    case bytecode[0]
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
      when :pre_call
        @num_partial_call_executing = @partial_calls.size - 1
        if @partial_calls.last == [@main, :gets]
          @accepting_input = true
        end
      when :call
        @num_partial_call_executing = nil
        call = @partial_calls.pop
        outputs = $captured_stdout.size
        if @accepted_input != nil
          result_is @accepted_input
          @accepted_input = nil
        else
          result_is do_call *call
        end
      when :start_var
        @started_var_names.push bytecode[1]
      when :to_var
        var_name = bytecode[1]
        @started_var_names = @started_var_names - [var_name]
        value = pop_result
        @vars[var_name] = value
        result_is value
      when :from_var
        var_name = bytecode[1]
        out = @vars[var_name]
        result_is out
      when :make_symbol
        result = pop_result
        `result.is_symbol = true;` if RUBY_PLATFORM == 'opal'
        result_is result
      when :goto_if_not
        pop_result
    end
    nil
  end

  def set_input text
    @accepted_input = text
    @accepting_input = false
  end

  def get_output
    $captured_stdout.join
  end

  private

  def result_is new_result
    @result.push new_result
    raise "Result stack has too many items: #{@result}" if @result.size > 1
  end

  def do_call receiver, method_name, *args
    if receiver == @main
      begin
        $is_capturing_stdout = true
        result = @main.send method_name, *args
        $is_capturing_stdout = false
        result
      rescue NoMethodError => e
        raise NameError.new "undefined local variable or method " +
          "`#{method_name}' for main:Object"
      end
    else
      $is_capturing_stdout = true
      result = receiver.send(method_name, *args)
      $is_capturing_stdout = false
      result
    end
  end

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end
end
