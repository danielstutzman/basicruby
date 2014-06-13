require 'opal'
require './ast_to_bytecode_compiler'

def compile ruby_code
  parser = Opal::Parser.new
  sexp = parser.parse ruby_code
  compiler = AstToBytecodeCompiler.new
  compiler.compile_program 'test', sexp
end

describe AstToBytecodeCompiler, '#compile' do
  it 'compiles blank' do
    compile('').should == [[:result, nil]]
  end
  it 'compiles 3' do
    compile('3').should == [[:position, "test", 1, 0], [:token, 1, 0], [:result, 3]]
  end
  it 'compiles puts 3' do
    compile('puts 3').should == [
      [:position, "test", 1, 0], [:start_call], [:top], [:arg],
      [:token, 1, 0], [:result, :puts], [:make_symbol], [:arg],
      [:result, nil], [:arg],
      [:token, 1, 5], [:result, 3], [:arg],
      [:pre_call], [:call],
    ]
  end
  it 'compiles 3; 4' do
    compile('3; 4').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:result, 3], [:discard],
      [:position, "test", 1, 3], [:token, 1, 3], [:result, 4],
    ]
  end
  it 'compiles (3)' do
    compile('(3)').should == [[:position, "test", 1, 0], [:token, 1, 1], [:result, 3]]
  end
  it 'compiles x = 3' do
    compile('x = 3').should == [
      [:position, "test", 1, 0],
      [:token, 1, 0], [:start_var, :x],
      [:token, 1, 4], [:result, 3],
      [:to_var, :x],
    ]
  end
  it 'compiles x = 3; x' do
    compile('x = 3; x').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:start_var, :x],
      [:token, 1, 4], [:result, 3], [:to_var, :x], [:discard],
      [:position, "test", 1, 7], [:token, 1, 7], [:from_var, :x],
    ]
  end
  it 'compiles x = if true then 3 end' do
    compile('x = if true then 3 end').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:start_var, :x],
      [:token, 1, 7], [:result, true],
      [:goto_if_not, "else_test_1_4"],
      [:position, "test", 1, 17],
      [:token, 1, 17], [:result, 3],
      [:goto, "endif_test_1_4"],
      [:label, "else_test_1_4"],
      [:result, nil],
      [:label, "endif_test_1_4"],
      [:to_var, :x],
    ]
  end
if false
  it 'compiles "1#{2}3"' do
    compile('"1#{2}3"').should == [
      [:position, "test", 1, 1],
      [:start_call], [:result, "1"], [:arg],
      [:result, :<<], [:arg],
      [:token, 1, 4], [:result, 2], [:arg],
      [:token, 1, 6], [:result, "3"], [:arg],
      [:pre_call], [:call],
    ]
  end
end
  it 'compiles puts ""' do
    compile('puts ""').should == [
      [:position, "test", 1, 0], [:start_call], [:top], [:arg],
      [:token, 1, 0], [:result, :puts], [:make_symbol], [:arg],
      [:result, nil], [:arg],
      [:result, ""], [:arg], [:pre_call], [:call]
    ]
  end

  it 'compiles lambda { 4 }' do
    compile('lambda { 4 }').should == [
      [:position, "test", 1, 0], [:start_call], [:top], [:arg],
      [:token, 1, 0], [:result, :lambda], [:make_symbol], [:arg],
      [:goto, "after_return_test_1_9"],
      [:label, "start_test_1_9"],
      [:args, 0, 0], [:vars_from_env_except], [:to_vars, nil, nil], [:discard],
      [:position, "test", 1, 9], [:token, 1, 9], [:result, 4],
      [:will_return], [:return],
      [:label, "after_return_test_1_9"], [:make_proc, "start_test_1_9"], [:arg],
      [:pre_call], [:call]
    ]
  end

  it 'compiles x,y=3,4' do
    compile('x,y=3,4').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:start_var, :x],
      [:token, 1, 2], [:start_var, :y],
      [:start_call], [:result, []], [:arg], [:result, :push],
      [:arg], [:result, nil],
      [:arg], [:token, 1, 4], [:result, 3],
      [:arg], [:token, 1, 6], [:result, 4],
      [:arg], [:pre_call], [:call],
      [:to_vars, nil, nil, :x, :y]
    ]
  end

  it 'compiles lambda{|x=1|}' do
    compile('lambda{|x=1|}').should == [
      [:position, "test", 1, 0], [:start_call],
      [:top], [:arg],
      [:token, 1, 0], [:result, :lambda], [:make_symbol], [:arg],
      [:goto, "after_return_test_1"], [:label, "start_test_2"],
      [:args, 0, 1], [:vars_from_env_except, :x],
      [:to_vars, nil, nil, :x],
      [:discard],
      [:goto_param_defaults,
        "param_defaults_test_3_0", "param_defaults_test_4_1"],
        [:label, "param_defaults_test_3_0"],
          [:token, 1, 8], [:start_var, :x], [:token, 1, 10],
          [:result, 1], [:to_var, :x], [:discard],
        [:label, "param_defaults_test_4_1"],
      [:result, nil], [:will_return], [:return],
      [:label, "after_return_test_1"],
      [:make_proc, "start_test_2"],
      [:arg], [:pre_call], [:call]
    ]
  end

  it 'compiles def f; 3; end' do
    compile('def f; 3; end').should == [
      [:position, "test", 1, 0], [:goto, "after_return_test_1_0"],
      [:label, "start_test_1_0"],
      [:args, 0, 0], [:vars_from_env_except], [:to_vars, nil, nil], [:discard],
      [:position, "test", 1, 7], [:token, 1, 7], [:result, 3],
      [:will_return], [:return], [:label, "after_return_test_1_0"],
      [:start_call], [:top], [:arg], [:result, :define_method], [:arg],
      [:make_proc, "start_test_1_0"], [:arg], [:result, :f], [:arg],
      [:pre_call], [:call]
    ]
  end

  it 'compiles lambda{|&b|}' do
    compile('lambda{|&b|}').should == [
      [:position, "test", 1, 0], [:start_call], [:top], [:arg],
      [:token, 1, 0], [:result, :lambda], [:make_symbol], [:arg],
      [:goto, "after_return_test_1"], [:label, "start_test_2"], [:args, 0, 0],
      [:vars_from_env_except, :b], [:to_vars, nil, 0, :b], [:discard],
      [:result, nil], [:will_return], [:return],
      [:label, "after_return_test_1"], [:make_proc, "start_test_2"],
      [:arg], [:pre_call], [:call]
    ]
  end

  # nil at the beginning to avoid nil source
  it 'compiles nil; while false; 3; end' do
    compile('nil; while false; 3; end').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:result, nil], [:discard],
      [:label, "start_test_1_11"], [:token, 1, 11], [:result, false],
      [:goto_if_not, "end_test_1_11"],
      [:token, 1, 18], [:result, 3], [:discard],
      [:goto, "start_test_1_11"], [:label, "end_test_1_11"], [:result, nil]
    ]
  end

  it 'compiles 2; begin; 3; rescue Exception => e; end' do
    compile('2; begin; 3; rescue Exception => e; end').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:result, 2], [:discard],
      [:push_rescue, "rescue_test_1"],
      [:token, 1, 10], [:result, 3], [:pop_rescue, "rescue_test_1"],
      [:goto, "end_rescue_test_2"],
      [:label, "rescue_test_1"], [:discard],
      [:start_call], [:token, 1, 20], [:const, :Exception], [:arg],
        [:result, :===], [:make_symbol], [:arg], [:result, nil], [:arg],
        [:from_gvar, :$!], [:arg], [:pre_call], [:call],
      [:goto_if_not, "endif_test_3"],
      [:token, 1, 33], [:start_var, :e], [:from_gvar, :$!], [:to_var, :e],
      [:discard], [:result, nil], [:goto, "end_rescue_test_2"],
      [:label, "endif_test_3"],
      [:start_call], [:top], [:arg], [:result, :raise], [:make_symbol], [:arg],
        [:result, nil], [:arg], [:pre_call], [:call],
      [:label, "end_rescue_test_2"], [:clear_dollar_bang]
    ]
  end

  it 'compiles $a' do
    compile('$a').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:from_gvar, :$a]
    ]
  end
  it 'compiles $a = 1' do
    compile('$a = 1').should == [
      [:position, "test", 1, 0], [:token, 1, 0], [:token, 1, 5],
        [:result, 1], [:to_gvar, :$a]
    ]
  end
end
