require './bytecode_interpreter.rb'
require 'opal'

class RspecRubyRunner
  def output_from ruby_code
    old_stdout = $stdout
    $stdout = StringIO.new
    parser = Opal::Parser.new
    sexp = parser.parse ruby_code
    compiler = AstToBytecodeCompiler.new
    bytecodes = compiler.compile_program sexp
    interpreter = BytecodeInterpreter.new bytecodes
    interpreter.run
    output = $stdout.string
    $stdout = old_stdout
    output
  end
end
