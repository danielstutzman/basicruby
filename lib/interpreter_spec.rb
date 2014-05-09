require 'opal'
require './lexer.rb'
require './interpreter.rb'

$main = self

def run code
  parser = Opal::Parser.new
  sexp = parser.parse code
  state = Interpreter.start
  start_pos_to_end_pos = Lexer.new.build_start_pos_to_end_pos code
  interpreter = Interpreter.new $main, start_pos_to_end_pos
  if sexp
    while state[:pos] != nil
      state = interpreter.advance state, sexp
    end
  end
  state
end

describe Interpreter, '#advance' do
  it 'runs blank' do
    run('')[:output].should == ''
  end
  it 'runs 3' do
    run('3')[:result].should == [3]
  end
  it 'runs 3 + 4' do
    run('3 + 4')[:result].should == [7]
  end
  it 'runs 3 + 4 + 5' do
    run('3 + 4 + 5')[:result].should == [12]
  end
  it 'runs 3 + (4 + 5)' do
    run('3 + (4 + 5)')[:result].should == [12]
  end

  it 'runs puts 3' do
    run('puts 3')[:output].should == "3\n"
  end
  it 'runs puts 3 + 4' do
    run('puts 3 + 4')[:output].should == "7\n"
  end

  it 'runs x = 4' do
    run('x = 4')[:result].should == [4]
  end
  it 'runs x = 4' do
    run("x = 4")[:vars].should == { :x => 4 }
  end
  it 'runs x = 4 \n puts x' do
    run("x = 4 \n puts x")[:output].should == "4\n"
  end

  it 'runs 3;4' do
    run("3;4")[:result].should == [4]
  end

  it 'runs x = if true then 3 else 4 end' do
    run("x = if true then 3 else 4 end")[:vars].should == { :x => 3 }
  end
  it 'runs x = if true then else 4 end' do
    run("x = if true then else 4 end")[:vars].should == { :x => nil }
  end
  it 'runs x = if false then 3 else 4 end' do
    run("x = if false then 3 else 4 end")[:vars].should == { :x => 4 }
  end
  it 'runs x = if false then 3 else end' do
    run("x = if false then 3 else end")[:vars].should == { :x => nil }
  end

  it 'runs p' do
    run("p")[:output].should == ""
    run("p")[:result].should == [nil]
  end
  it 'runs p 3' do
    run("p 3")[:output].should == "3\n"
    run("p 3")[:result].should == [3]
  end
  it 'runs p 3, 4' do
    run("p 3, 4")[:output].should == "3\n4\n"
    run("p 3, 4")[:result].should == [[3, 4]]
  end

  it 'runs x = if true then (if true then 3 else 4 end) else 5 end' do
    run("x = if true then (if true then 3 else 4 end) else 5 end"
      )[:vars].should == { :x => 3 }
  end
  it 'runs x = if true then (if false then 3 else 4 end) else 5 end' do
    run("x = if true then (if false then 3 else 4 end) else 5 end"
      )[:vars].should == { :x => 4 }
  end
  it 'runs x = if false then (if true then 3 else 4 end) else 5 end' do
    run("x = if false then (if true then 3 else 4 end) else 5 end"
      )[:vars].should == { :x => 5 }
  end

  it 'runs "a"' do
    run('"a"')[:result].should == ['a']
  end
  it 'runs "a#{1}"' do
    run('"a#{1}"')[:result].should == ['a1']
  end
  it 'runs "#{1}"' do
    run('"#{1}"')[:result].should == ['1']
  end
  it 'runs "#{1}2"' do
    run('"#{1}2"')[:result].should == ['12']
  end

  it 'runs nil' do
    run('nil')[:result].should == [nil]
  end
  it 'runs 3.0' do
    run('3.0')[:result].should == [3.0]
  end

end
