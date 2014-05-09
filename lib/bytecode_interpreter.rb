if RUBY_VERSION == 'opal'
  require 'interpreter_state'
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


=begin
    when :push_arg
      new_partial_calls = state[:partial_calls].clone
      partial_call = new_partial_calls.last
      raise 'Hit bottom of result stack' if state[:result].size == 0
      partial_call.push state[:result].pop
      state[:partial_calls] = new_partial_calls
    when :enter
      state[:pos] = state[:pos] + [0]
    when :exit
      if state[:pos][0...-1] == []
        state[:pos] = nil # done with program
      else
        state[:pos] = state[:pos][0...-2] + [state[:pos][-2] + 1]
      end
    when :call
      new_partial_calls = state[:partial_calls].clone
      receiver, method_name, *args = new_partial_calls.pop
      results = do_call receiver, method_name, args
      state[:result].push results[:new_result]
      state[:output] += results[:new_output]
      state[:partial_calls] = new_partial_calls
    when :set_result
      state[:result].push todo[1]
    when :next
      advance_pos(state)
    when :assign_to
      var_name = todo[1]
      raise 'Hit bottom of result stack' if state[:result].size == 0
      value = state[:result].pop
      state[:vars][var_name] = value
      state[:result].push value
    when :pop_result
      raise 'Hit bottom of result stack' if state[:result].size == 0
      state[:result].pop
    when :lookup_var
      var_name = todo[1]
      state[:result].push state[:vars][var_name]
    when :push_if
      raise 'Hit bottom of result stack' if state[:result].size == 0
      state[:ifs].push state[:result].pop
    when :enter_if
      if state[:ifs].last == todo[1] # compare the two bools
        state[:pos] = state[:pos] + [0] # enter
      else
        advance_pos(state)
      end
    when :pop_if
      raise 'Hit bottom of ifs stack' if state[:ifs].size == 0
      state[:ifs].pop
    when :highlight
      p [todo[0], todo[1], @start_pos_to_end_pos[todo[1]]]
=end






=begin
          when :arg
            @partial_calls.last.push result
          when :int
            @result = arg0
          when :float
            @result = arg0
          when :string
            @result = arg0
          when :nil
            @result = nil
          when :bool
            @result = arg0
          when :call
            do_call arg0
          when :goto
            @pos = arg0
            break
          when :assign_to
            @vars[arg0] = @result
            # leave result unchanged
          when :lookup_var
            @result = @vars[arg0]
          when :if_goto
            if @result != false && @result != nil
              @pos = arg0
              @result = ResultIsUnassigned
              break
            else
              @pos = arg1
              @result = ResultIsUnassigned
              break
            end
          else
            raise "Unknown bytecode head #{head}"
        end
      end
    rescue ProgramTerminated => e
      @step_output += "#{e.message}\n"
      @pos = nil
    end
  end

  def do_call method_name
    receiver, *args = @partial_calls.pop
    if receiver == ResultIsUnassigned && method_name == :puts
      if args.size == 0
        @step_output += "\n"
      else
        @step_output += args.map { |arg| "#{arg}\n" }.join
      end
      @result = nil
    elsif receiver == ResultIsUnassigned && method_name == :p
      if args.size == 0
        @result = nil
      elsif args.size == 1
        @step_output += "#{args[0].inspect}\n"
        @result = args[0]
      else
        @step_output += args.map { |arg| "#{arg.inspect}\n" }.join
        @result = args
      end
    elsif receiver == ResultIsUnassigned && method_name == :__STRINTERP
      @result = args.map { |arg| arg.to_s }.join
    elsif receiver == ResultIsUnassigned
      if @main.methods.include? method_name
        @result = @main.send method_name, *args
      else
        begin
          raise NameError.new "undefined local variable or method " +
            "`#{method_name}' for main:Object"
        rescue NameError => e
          raise ProgramTerminated.new e
        end
      end
    else
      begin
        if receiver.private_methods.include? method_name
          message = "private method `#{method_name}' called for " +
            "#{receiver.inspect}:#{receiver.class}"
          raise NoMethodError.new message
        else
          @result = receiver.send method_name, *args
        end
      rescue NoMethodError => e
        raise ProgramTerminated.new e
      rescue TypeError => e
        raise ProgramTerminated.new e
      end
    end
  end
end
=end
