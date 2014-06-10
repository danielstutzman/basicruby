require 'opal'
require './ast_to_bytecode_compiler'
require './bytecode_interpreter'
require './rspec_ruby_runner'

$main = self

def output_of ruby_code
  RspecRubyRunner.new.output_from ruby_code
end

describe BytecodeInterpreter, '#run' do
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

  it 'runs p nil' do
    output_of("p nil").should == "nil\n"
  end
  it 'runs p 3' do
    output_of("p 3").should == "3\n"
  end
  it 'runs p 3, 4' do
    output_of("p 3, 4").should == "3\n4\n"
  end
  it 'runs p p' do
    output_of("p p").should == "nil\n"
  end
  it 'runs p p 3' do
    output_of("p p 3").should == "3\n3\n"
  end
  it 'runs p p 3, 4' do
    output_of("p p 3, 4").should == "3\n4\n[3, 4]\n"
  end

  it 'runs x = 3 \n p x' do
    output_of("x = 3\np x").should == "3\n"
  end
  it 'raises NameError from p x' do
    expect { output_of("p x") }.to raise_exception(NameError)
  end
  it 'prints main from puts to_s' do
    output_of("puts to_s").should == "main\n"
  end

  it 'runs puts "3#{4}5"' do
    output_of('puts "3#{4}5"').should == "345\n"
  end

  it 'runs if true \n p 3 \n p4 \n end \n p 5' do
    output_of("if true \n p 3 \n p 4 \n end \n p 5").should == "3\n4\n5\n"
  end
  it 'runs if true \n p 3 \n end' do
    output_of("if true \n p 3 \n end").should == "3\n"
  end
  it 'runs if true \n p 3 \n end \n p 4' do
    output_of("if true \n p 3 \n end \n p 4").should == "3\n4\n"
  end
  it 'runs if false \n p 3 \n p4 \n end \n p 5' do
    output_of("if false \n p 3 \n p 4 \n end \n p 5").should == "5\n"
  end
  it 'runs if false \n p 3 \n end' do
    output_of("if false \n p 3 \n end").should == ""
  end
  it 'runs if false \n p 3 \n end \n p 4' do
    output_of("if false \n p 3 \n end \n p 4").should == "4\n"
  end
  it 'runs if true \n end \n' do
    output_of("if true \n end").should == ""
  end
  it 'runs if true \n end \n p 3' do
    output_of("if true \n end \n p 3").should == "3\n"
  end

  it 'runs if true \n p 3 \n else \n p 4 \n end \n p 5' do
    output_of("if true \n p 3 \n else \n p 4 \n end \n p 5").should ==
      "3\n5\n"
  end
  it 'runs if false \n p 3 \n else \n p 4 \n end \n p 5' do
    output_of("if false \n p 3 \n else \n p 4 \n end \n p 5").should ==
      "4\n5\n"
  end

  it 'runs if true \n p 3 \n elsif false \n p 4 \n end' do
    output_of("if true \n p 3 \n elsif false \n p 4 \n end").should == "3\n"
  end
  it 'runs if false \n p 3 \n elsif true \n p 4 \n end' do
    output_of("if false \n p 3 \n elsif true \n p 4 \n end").should == "4\n"
  end
  it 'runs if false \n p 3 \n elsif false \n p 4 \n end' do
    output_of("if false \n p 3 \n elsif false \n p 4 \n end").should == ""
  end
  it 'runs if true \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end' do
    output_of("if true \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end"
      ).should == "3\n"
  end
  it 'runs if false \n p 3 \n elsif true \n p 4 \n else \n p 5 \n end' do
    output_of("if false \n p 3 \n elsif true \n p 4 \n else \n p 5 \n end"
      ).should == "4\n"
  end
  it 'runs if false \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end' do
    output_of("if false \n p 3 \n elsif false \n p 4 \n else \n p 5 \n end"
      ).should == "5\n"
  end

  it 'runs x = if true then 3 end; p x' do
    output_of("x = if true then 3 end; p x").should == "3\n"
  end
  it 'runs x = if false then 3 end; p x' do
    output_of("x = if false then 3 end; p x").should == "nil\n"
  end

  it 'runs p lambda {3}.call' do
    output_of("p lambda {3}.call").should == "3\n"
  end
  it 'runs p lambda {3}.call + 2' do
    output_of("p lambda {3}.call + 2").should == "5\n"
  end
  it 'runs p lambda {3+2}.call' do
    output_of("p lambda {3+2}.call").should == "5\n"
  end
  it 'runs lambda {x=3}.call; p x' do
    expect { output_of("lambda {x=3}.call; p x") }.to raise_exception(NameError)
  end
  it 'runs x=5; lambda {x=3}.call; p x' do
    output_of("x=5; lambda {x=3}.call; p x").should == "3\n"
  end
  it 'runs x=5; lambda {p x}.call' do
    output_of("x=5; lambda {p x}.call").should == "5\n"
  end
  it 'runs p lambda { x=5; lambda {x} }.call.call' do
    output_of("p lambda { x=5; lambda {x} }.call.call").should == "5\n"
  end
  it 'runs lambda { x=5; lambda {x} }.call.call; p x' do
    expect {
      output_of("lambda { x=5; lambda {x} }.call.call; p x")
    }.to raise_exception(NameError)
  end

  it 'runs lambda {|x| p x}.call(3)' do
    output_of("lambda {|x| p x}.call(3)").should == "3\n"
  end
  it 'runs x = 1; lambda {|x| p x}.call(2); p x' do
    output_of("x = 1; lambda {|x| p x}.call(2); p x").should == "2\n1\n"
  end
  it 'runs lambda {|x, y| p x, y }.call(3, 4)' do
    output_of("lambda {|x, y| p x, y }.call(3, 4)").should == "3\n4\n"
  end
  it 'runs x, y = 3, 4; p x, y' do
    output_of("x, y = 3, 4; p x, y").should == "3\n4\n"
  end
  it 'runs x,*y = 3,4,5; p x,y' do
    output_of("x,*y = 3,4,5; p x,y").should == "3\n[4, 5]\n"
  end
  it 'runs lambda {|x,*y| p x, y }.call(3,4,5)' do
    output_of("lambda {|x,*y| p x, y }.call(3,4,5)").should == "3\n[4, 5]\n"
  end
  it 'runs lambda {|x=1| p x }.call()' do
    output_of("lambda {|x=1| p x }.call").should == "1\n"
  end
  it 'runs lambda {|x=1| p x }.call(2)' do
    output_of("lambda {|x=1| p x }.call(2)").should == "2\n"
  end
  it 'runs lambda {}.call(2)' do
    expect { output_of("lambda {}.call(2)") }.to raise_exception(ArgumentError)
  end
  it 'runs lambda {|x=1|}.call' do
    output_of("lambda {|x=1|}.call").should == "" # no error
  end
  it 'runs lambda {|*x|}.call' do
    output_of("lambda {|*x|}.call").should == "" # no error
  end
  it 'runs lambda {|*x|}.call(1,2)' do
    output_of("lambda {|*x|}.call(1,2)").should == "" # no error
  end
  it 'runs lambda {|x=1,y=2| p x, y }.call' do
    output_of("lambda {|x=1,y=2| p x, y }.call").should == "1\n2\n"
  end
  it 'runs lambda {|x=1,y=2| p x, y }.call(3)' do
    output_of("lambda {|x=1,y=2| p x, y }.call(3)").should == "3\n2\n"
  end
  it 'runs lambda {|x=1,y=2| p x, y }.call(3,4)' do
    output_of("lambda {|x=1,y=2| p x, y }.call(3,4)").should == "3\n4\n"
  end
  it 'runs def f; 3; end; p f' do
    output_of("def f; 3; end; p f").should == "3\n"
  end
  it 'runs def f(x); x; end; p f(1)' do
    output_of("def f(x); x; end; p f(1)").should == "1\n"
  end
  it 'runs def f(x); x; end; p f' do
    expect { output_of("def f(x); x; end; p f")
      }.to raise_exception(ArgumentError)
  end
  it 'runs def f(x, *y); [x, y]; end; p f(1, 2, 3)' do
    output_of("def f(x, *y); [x, y]; end; p f(1, 2, 3)").should ==
      "[1, [2, 3]]\n"
  end
  it 'runs def f(x=1, y=2); p x, y; end; f' do
    output_of("def f(x=1, y=2); p x, y; end; f").should == "1\n2\n"
  end
  it 'runs def f(x=1, y=2); p x, y; end; f 3' do
    output_of("def f(x=1, y=2); p x, y; end; f 3").should == "3\n2\n"
  end
  it 'runs def f(x=1, y=2); p x, y; end; f 3, 4' do
    output_of("def f(x=1, y=2); p x, y; end; f 3, 4").should == "3\n4\n"
  end
  it 'runs a=[]; def a.f; 3; end; p a.f' do
    output_of("a=[]; def a.f; 3; end; p a.f").should == "3\n"
  end
  it 'runs def f(&b); b.call; end; f { p 3 }' do
    output_of("def f(&b); b.call; end; f { p 3 }").should == "3\n"
  end
  it 'runs def f(a, &b); p a; b.call; end; f(2) { p 3 }' do
    output_of("def f(a, &b); p a; b.call; end; f(2) { p 3 }").should ==
      "2\n3\n"
  end
  it 'runs def f; yield; end; f { p 3 }' do
    output_of("def f; yield; end; f { p 3 }").should == "3\n"
  end
  it 'runs def f; yield 3; end; f { |x| p x }' do
    output_of("def f; yield 3; end; f { |x| p x }").should == "3\n"
  end

  it 'runs n = 1; while n <= 3; puts n; n += 1; end' do
    output_of("n = 1; while n <= 3; puts n; n += 1; end").should == "1\n2\n3\n"
  end

  it 'runs [1, 2, 3].each { |x| p x }' do
    output_of("[1, 2, 3].each { |x| p x }").should == "1\n2\n3\n"
  end
end
