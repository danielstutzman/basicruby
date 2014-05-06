require './bytecode_compiler'

describe BytecodeCompiler, '#compile' do
  it 'can compile a blank string' do
    compiler = BytecodeCompiler.new
    compiler.compile('').should == 0
  end
end
