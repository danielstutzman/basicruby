require 'opal'
require './bytecode_compiler'

Compiler = BytecodeCompiler.new
def compile ruby_code
  Compiler.compile ruby_code
end

describe BytecodeCompiler, '#compile' do
  it 'compiles 3' do
    compile('3').should == [[:int, 3]]
  end
  it 'compiles puts 3' do
    compile('puts 3').should == [[:int, 3], [:arg], [:call, :puts]]
  end
end
