if RUBY_PLATFORM == 'opal'
  require 'interpreter_state.rb'
else
  send :require, './interpreter_state'
end

class BytecodeInterpreter
  def initialize main, bytecodes
    @main = main
    @bytecodes = bytecodes
    @counter = 0
    @state = InterpreterState.new
    @label_to_counter = label_to_counter(bytecodes)
  end

  def set_output_handler &do_output
    @do_output = do_output
  end

  def run
    while @counter < @bytecodes.size
      bytecode = @bytecodes[@counter]
      break if bytecode.nil?

      case bytecode[0]
        when :call
          result = do_call *@state.pop_call
          @state.result result
        when :token, :position, :label
          # noop
        when :if_goto
          if bytecode[1] == @state.if_was_true?
            @counter = @label_to_counter.fetch bytecode[2]
          end
        when :start_call, :result, :arg, :token, :discard, :push_if, :pop_if,
             :to_var, :from_var
          @state.send *bytecode
        else
          raise "Unknown bytecode head #{bytecode[0]}"
      end

      @counter += 1 # ok to step past label
    end
  end

  private

  def label_to_counter bytecodes
    hash = {}
    bytecodes.each_with_index do |bytecode, counter|
      if bytecode[0] == :label
        label_name = bytecode[1]
        hash[label_name] = counter
      end
    end
    hash
  end

  def do_call receiver, method_name, *args
    #p [receiver, method_name, *args]
    if receiver == @main && method_name == :puts
      do_call_puts *args
    elsif receiver == @main && method_name == :p
      do_call_p *args
    elsif receiver == @main && method_name == :__STR_INTERP
      args.map { |arg| "#{arg}" }.join
    elsif receiver == @main
      if @main.methods.include? method_name
        @main.send method_name, *args
      else
        raise NameError.new "undefined local variable or method " +
          "`#{method_name}' for main:Object"
      end
    else
      receiver.send(method_name, *args)
    end
  end

  def do_call_puts *args
    if args.size == 0
      @do_output.call "\n"
    else
      @do_output.call args.map { |arg| "#{arg}\n" }.join
    end
    nil
  end

  def do_call_p *args
    if args.size == 0
      nil
    elsif args.size == 1
      @do_output.call "#{args[0].inspect}\n"
      args[0]
    else
      @do_output.call args.map { |arg| "#{arg.inspect}\n" }.join
      args
    end
  end
end
