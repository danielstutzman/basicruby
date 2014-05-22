if RUBY_PLATFORM == 'opal'
  def gets
    `window.$stdin_is_waiting = true;`
  end

  def puts *args
    if args.size > 0
      $stdout.write args.map { |arg| "#{arg}\n" }.join
    else
      $stdout.write "\n"
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

    $console_texts = []
  end

  def visible_state
    {
      partial_calls: @partial_calls.map { |call| call.clone },
      started_var_names: @started_var_names,
      vars: @vars,
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
        if @accepted_input != nil
          result_is @accepted_input
          @accepted_input = nil
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
    $console_texts = $console_texts.clone + [[:stdin, text]]
  end

  def get_stdout
    stdout_pairs = $console_texts.select { |pair| pair[0] == :stdout }
    stdout_pairs.map { |pair| pair[1] }.join
  end

  def get_stderr
    stderr_pairs = $console_texts.select { |pair| pair[0] == :stderr }
    stderr_pairs.map { |pair| pair[1] }.join
  end

  private

  def result_is new_result
    @result.push new_result
    raise "Result stack has too many items: #{@result}" if @result.size > 1
  end

  def do_call receiver, method_name, *args
    begin
      if receiver == @main
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
        result = receiver.send(method_name, *args)
        $is_capturing_stdout = false
        result
      end
    rescue Exception => e
      text = "#{e.class}: #{e.message}\n"
      $console_texts = $console_texts.clone + [[:stderr, text]]
      raise ProgramTerminated.new
    end
  end

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end
end
