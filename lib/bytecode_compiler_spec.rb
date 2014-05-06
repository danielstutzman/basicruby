require 'opal'
require './bytecode_compiler'

Compiler = BytecodeCompiler.new
def program ruby_code
  Compiler.compile_ruby_program_to_hash ruby_code
end
def exp ruby_code
  Compiler.compile_ruby_expression_to_bytecodes ruby_code
end

describe BytecodeCompiler, '#compile' do
  it 'compiles blank' do
    program('').should == {}
  end
  it 'compiles 3' do
    program('3').should == {
      :start=>'1,0',
      '1,0'=>[[:int, 3], [:done]],
    }
  end
  it 'compiles puts 3' do
    program('puts 3').should == {
      :start=>"1,0",
      "1,0"=>[[:int, 3], [:arg], [:call, :puts], [:done]],
    }
  end
  it 'compiles puts 3; puts 4' do
    program('puts 3; puts 4').should == {
      :start=>"1,0",
     "1,0" => [[:int, 3], [:arg], [:call, :puts], [:goto, "1,8"]],
     "1,8" => [[:int, 4], [:arg], [:call, :puts], [:done]],
    }
  end
  it 'compiles puts 3\nputs 4' do
    program("puts 3\nputs 4").should == {
      :start=>"1,0",
     "1,0" => [[:int, 3], [:arg], [:call, :puts], [:goto, "2,0"]],
     "2,0" => [[:int, 4], [:arg], [:call, :puts], [:done]],
    }
  end

  it 'compiles expression 3' do
    exp('3').should == [[:int, 3]]
  end
  it 'compiles expression 3 + 4' do
    exp('3 + 4').should == [[:int, 4], [:arg], [[:int, 3]], [:call, :+]]
  end
end
