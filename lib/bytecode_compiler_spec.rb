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
      '1,0'=>[[:int, 3], [:goto, nil]],
    }
  end
  it 'compiles puts 3' do
    program('puts 3').should == {
      :start=>"1,0",
      "1,0"=>[
        [:start_call], [:arg], [:int, 3], [:arg], [:call, :puts], [:goto, nil]
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
       [:start_call], [:arg], [:int, 4], [:arg], [:call, :puts], [:goto, nil]
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
       [:start_call], [:arg], [:int, 4], [:arg], [:call, :puts], [:goto, nil]
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
        [:lookup_var, :x], [:arg], [:call, :p], [:goto, nil]]
    }
  end

  it 'compiles "#{4}"' do
    exp('"#{4}"').should == [[:start_call], [:arg],
      [:int, 4], [:arg], [:call, :__STRINTERP]]
  end
  it 'compiles "3#{4}"' do
    exp('"3#{4}"').should == [[:start_call], [:arg], [:string, "3"], [:arg],
      [:int, 4], [:arg], [:call, :__STRINTERP]]
  end
  it 'compiles "3#{4}5"' do
    exp('"3#{4}5"').should == [[:start_call], [:arg], [:string, "3"], [:arg],
      [:int, 4], [:arg], [:string, "5"], [:arg], [:call, :__STRINTERP]]
  end

  it 'compiles if true \n 3 \n end' do
    program("if true\n3\nend").should == {
      :start => "1,0",
      "1,0" => [[:bool, true], [:if_goto, "2,0", nil]],
      "2,0" => [[:int, 3], [:goto, nil]],
    }
  end
  it 'compiles if true \n 3 \n 4 \n end \n 5' do
    program("if true\n3\n4\nend\n5").should == {
      :start=>"1,0",
      "1,0"=>[[:bool, true], [:if_goto, "2,0", "5,0"]],
      "2,0"=>[[:int, 3], [:goto, "3,0"]],
      "3,0"=>[[:int, 4], [:goto, "5,0"]],
      "5,0"=>[[:int, 5], [:goto, nil]]
    }
  end

  it 'compiles if true \n 3 \n else \n 4 \n end' do
    program("if true\n3\nelse\n4\nend").should == {
      :start => "1,0",
      "1,0" => [[:bool, true], [:if_goto, "2,0", "4,0"]],
      "2,0" => [[:int, 3], [:goto, nil]],
      "4,0" => [[:int, 4], [:goto, nil]]
    }
  end
end
