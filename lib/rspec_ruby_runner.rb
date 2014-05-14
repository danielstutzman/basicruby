require './bytecode_interpreter.rb'
require './bytecode_spool.rb'
require 'opal'

class RspecRubyRunner
  def output_from ruby_code
    parser = Opal::Parser.new
    sexp = parser.parse ruby_code
    compiler = AstToBytecodeCompiler.new
    bytecodes = compiler.compile_program sexp
    spool = BytecodeSpool.new bytecodes
    spool.queue_run_until 'DONE'
    interpreter = BytecodeInterpreter.new
    while true
      bytecode = spool.get_next_bytecode interpreter.is_result_truthy?
      break if bytecode.nil?
      interpreter.interpret bytecode
    end
    interpreter.visible_state[:output].join
  end
end
