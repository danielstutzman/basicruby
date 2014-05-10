if RUBY_PLATFORM != 'opal'
  send :require, './interpreter_state'
else
  require 'interpreter_state.rb'

  def $stdout.write(string)
    `if (!window.$output_to_stdout) { window.$output_to_stdout = []; };`
    `window.$output_to_stdout.push(string + "\n");`
  end
end

class String
  def <<(*args)
    self + args.map { |arg| "#{arg}" }.join
  end
end

class BytecodeInterpreter
  attr_reader :state

  def initialize bytecodes
    @bytecodes = bytecodes
    @counter = 0
    @state = InterpreterState.new
    @label_to_counter = label_to_counter(bytecodes)
    @main = (RUBY_PLATFORM == 'opal') ?
      `Opal.top` : TOPLEVEL_BINDING.eval('self')
  end

  def run
    while have_more_bytecodes?
      self.run_next_bytecode
    end
  end

  def have_more_bytecodes?
    @counter < @bytecodes.size
  end

  def run_next_bytecode
    bytecode = @bytecodes[@counter]
    case bytecode[0]
      when :call
        result = do_call *@state.pop_call
        @state.result result
      when :position
        # noop
      when :token
        # noop
      when :label
        # noop
      when :start_var
        # noop
      when :goto
        @counter = @label_to_counter.fetch bytecode[1]
      when :goto_if_not
        if !@state.result_is_true?
          @counter = @label_to_counter.fetch bytecode[1]
        end
      when :start_call, :result, :arg, :discard, :to_var, :from_var, :top,
           :make_symbol
        @state.send *bytecode
      else
        raise "Unknown bytecode head #{bytecode[0]}"
    end
    @counter += 1 # ok to step past label
    bytecode
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
    if receiver == @main
      begin
        @main.send method_name, *args
      rescue NoMethodError => e
        raise NameError.new "undefined local variable or method " +
          "`#{method_name}' for main:Object"
      end
    else
      receiver.send(method_name, *args)
    end
  end
end
