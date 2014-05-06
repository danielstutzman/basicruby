class BytecodeInterpreter
  def execute_hash hash
    output = ''
    line = hash[:start]
    partial_call = []
    result = nil
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
          when :call
            receiver, *args = partial_call.pop
            method_name = arg0
            if receiver == nil && method_name == :puts
              if args.size == 0
                output += "\n"
              else
                output += args.map { |arg| "#{arg}\n" }.join
              end
              result = nil
            else
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
            result = nil
            line = arg0
          else
            raise "Unknown bytecode head #{head}"
        end
      end
    end
    output
  end
end
