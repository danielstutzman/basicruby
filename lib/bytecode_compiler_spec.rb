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
      "1,0"=>[
        [:start_call], [:arg], [:int, 3], [:arg], [:call, :puts], [:done]
      ],
    }
  end
  it 'compiles puts 3; puts 4' do
    program('puts 3; puts 4').should == {
      :start=>"1,0",
     "1,0" => [
       [:start_call], [:arg], [:int, 3], [:arg], [:call, :puts], [:goto, "1,8"]
     ],
     "1,8" => [
       [:start_call], [:arg], [:int, 4], [:arg], [:call, :puts], [:done]
     ],
    }
  end
  it 'compiles puts 3\nputs 4' do
    program("puts 3\nputs 4").should == {
      :start=>"1,0",
     "1,0" => [
       [:start_call], [:arg], [:int, 3], [:arg], [:call, :puts], [:goto, "2,0"]
     ],
     "2,0" => [
       [:start_call], [:arg], [:int, 4], [:arg], [:call, :puts], [:done]
     ],
    }
  end

  it 'raises SyntaxError for puts 3 4' do
    expect { program "puts 3 4" }.to raise_error(SyntaxError)
  end

  it 'compiles expression 3' do
    exp('3').should == [[:int, 3]]
  end
  it 'compiles expression 3 + 4' do
    exp('3 + 4').should == [
      [:start_call], [:int, 3], [:arg], [:int, 4], [:arg], [:call, :+]
    ]
  end
  it 'compiles expression 3 + 4 + 5' do
    exp('3 + 4 + 5').should == [
      [:start_call],
      [:start_call], [:int, 3], [:arg], [:int, 4], [:arg], [:call, :+],
      [:arg], [:int, 5], [:arg], [:call, :+]
    ]
  end
  it 'compiles expression 3 + (4 + 5)' do
    exp('3 + (4 + 5)').should == [
      [:start_call], [:int, 3], [:arg],
      [:start_call], [:int, 4], [:arg], [:int, 5], [:arg], [:call, :+],
      [:arg], [:call, :+]
    ]
  end

  it 'compiles expression 0.5' do
    exp('0.5').should == [[:float, 0.5]]
  end
  it 'compiles expression "abc"' do
    exp('"abc"').should == [[:string, 'abc']]
  end

  it 'compiles expression x = 3' do
    exp('x = 3').should == [[:int, 3], [:assign_to, :x]]
  end
  it 'compiles x = 3 \n p x' do
    program("x = 3\np x").should == {
      :start=>"1,0",
      "1,0"=>[[:int, 3], [:assign_to, :x], [:goto, "2,0"]],
      "2,0"=>[[:start_call], [:arg],
        [:lookup_var, :x], [:arg], [:call, :p], [:done]]
    }
  end
end
