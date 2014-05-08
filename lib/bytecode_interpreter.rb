class BytecodeInterpreter
  class ResultIsUnassigned
  end

  class ProgramTerminated < RuntimeError
  end

  attr_accessor :pos, :partial_calls, :step_output, :result, :vars

  def initialize main, hash
    @main = main
    @hash = hash
    @step_output = nil
    @pos = hash[:start]
    @partial_calls = []
    @result = ResultIsUnassigned
    @vars = {}
  end

  def run
    all_output = ''
    while @pos
      step
      all_output += @step_output
    end
    all_output
  end

  def step
    raise "No more instructions" if @pos.nil?
    @step_output = ''
    @result = ResultIsUnassigned
    begin
      bytecodes = @hash[@pos]
      bytecodes.each do |bytecode|
        head, arg0, arg1 = bytecode
        case head
          when :start_call
            @partial_calls.push []
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
