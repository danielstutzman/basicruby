require './bytecode_interpreter.rb'
require './bytecode_spool.rb'
require 'opal'

class RspecRubyRunner
  def output_from ruby_code
    parser = Opal::Parser.new
    compiler = AstToBytecodeCompiler.new
    sexp1 = parser.parse BytecodeInterpreter.RUNTIME_PRELUDE
    bytecodes1 = compiler.compile_program sexp1
    bytecodes1.reject! { |bytecode| [:position, :token].include?(bytecode[0]) }
    sexp2 = parser.parse ruby_code
    bytecodes2 = compiler.compile_program sexp2
    spool = BytecodeSpool.new bytecodes1 + [[:discard]] + bytecodes2
    spool.queue_run_until 'DONE'
    interpreter = BytecodeInterpreter.new
    begin
      while true
        bytecode = spool.get_next_bytecode interpreter.is_result_truthy?,
          interpreter.gosubbing_label, interpreter.gotoing_label
        break if bytecode.nil?
        interpreter.interpret bytecode
      end
      interpreter.visible_state[:output].map { |pair| pair[1] }.join
    rescue ProgramTerminated => e
      raise e.cause
    end
  end
end
