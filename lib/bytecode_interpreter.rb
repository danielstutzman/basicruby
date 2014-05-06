class BytecodeInterpreter
  class ResultIsUnassigned
  end

  def initialize(main)
    @main = main
  end
  def execute_hash hash
    output = ''
    line = hash[:start]
    partial_call = []
    result = ResultIsUnassigned
    while line
      bytecodes = hash[line]
      bytecodes.each do |bytecode|
        head, arg0 = bytecode
        case head
          when :start_call
            partial_call.push []
          when :arg
            partial_call.last.push result
          when :int
            result = arg0
          when :nil
            result = nil
          when :call
            receiver, *args = partial_call.pop
            method_name = arg0
            if receiver == ResultIsUnassigned && method_name == :puts
              if args.size == 0
                output += "\n"
              else
                output += args.map { |arg| "#{arg}\n" }.join
              end
              result = nil
            elsif receiver == ResultIsUnassigned && method_name == :p
              if args.size == 0
                result = nil
              elsif args.size == 1
                output += "#{args[0].inspect}\n"
                result = args[0]
              else
                output += args.map { |arg| "#{arg.inspect}\n" }.join
                result = args
              end
            else
              if receiver == ResultIsUnassigned
                receiver = @main
              end
              if receiver.private_methods.include?(method_name)
                message = "private method `#{method_name}' called for " +
                  "#{receiver.inspect}:#{receiver.class}"
                raise NoMethodError.new(message)
              else
                result = receiver.send method_name, *args 
              end
            end
          when :done
            line = nil
          when :goto
            result = ResultIsUnassigned
            line = arg0
          else
            raise "Unknown bytecode head #{head}"
        end
      end
    end
    output
  end
end
