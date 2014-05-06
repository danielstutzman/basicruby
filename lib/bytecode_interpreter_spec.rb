require './bytecode_interpreter'

Compiler2 = BytecodeCompiler.new
Interpreter = BytecodeInterpreter.new
def output_of ruby_code
  hash = Compiler2.compile_ruby_program_to_hash ruby_code
  Interpreter.execute_hash hash
end

describe BytecodeInterpreter, '#execute_hash' do
  it 'runs puts 3' do
    output_of('puts 3').should == "3\n"
  end
  it 'runs puts 3; puts 4' do
    output_of('puts 3; puts 4').should == "3\n4\n"
  end
  it 'runs puts 3\nputs 4' do
    output_of("puts 3\nputs 4").should == "3\n4\n"
  end
  it 'runs puts 3 + 4' do
    output_of("puts 3 + 4").should == "7\n"
  end
  it 'runs puts 3 + 4 + 5' do
    output_of("puts 3 + 4 + 5").should == "12\n"
  end
  it 'runs puts 3 + (4 + 5)' do
    output_of("puts 3 + (4 + 5)").should == "12\n"
  end
end
