require 'opal'
require './bytecode_compiler'

Compiler = BytecodeCompiler.new
def program ruby_code
  Compiler.compile_program ruby_code
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
end
