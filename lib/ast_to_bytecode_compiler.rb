class AstToBytecodeCompiler
  # bytecodes need to have position at the front; the debugger is counting
  # on this to know where to start.
  def compile_program sexp
    if sexp.nil?
      position = [] # because the debugger special-cases this possibility
    elsif sexp[0] == :block
      position = [] # because position will be printed anyway
    elsif sexp.source
      position = [[:position] + sexp.source]
    else
      no 'top s-exp with nil source'
    end

    position + compile(sexp)
  end

  private

  class AssertionFailed < RuntimeError
  end

  class DebuggerDoesntYetSupport < RuntimeError
  end

  def assert bool
    raise AssertionFailed if !bool
  end

  def no feature
    raise DebuggerDoesntYetSupport.new(feature)
  end

  def compile sexp
    return [[:result, nil]] if sexp.nil?
    case sexp[0]
      when :int     then [[:token] + sexp.source, [:result, sexp[1]]]
      when :float   then [[:token] + sexp.source, [:result, sexp[1]]]
      when :str     then [[:token] + sexp.source, [:result, sexp[1]]]
      when :nil     then [[:token] + sexp.source, [:result, nil]]
      when :true    then [[:token] + sexp.source, [:result, true]]
      when :false   then [[:token] + sexp.source, [:result, false]]
      when :block   then compile_block sexp
      when :call    then compile_call sexp
      when :arglist then compile_arglist sexp
      when :paren   then compile sexp[1]
      when :lasgn   then compile_lasgn sexp
      when :lvar    then compile_lvar sexp
      when :if      then compile_if sexp
      when :dstr    then compile_dstr sexp
      when :evstr   then compile sexp[1]
      else no "s-exp with head #{sexp[0]}"
    end
  end

  def compile_block sexp
    _, *statements = sexp
    bytecodes = []

    statements.each_with_index do |statement, i|
      if statement.source
        bytecodes.push [:position] + statement.source
      end
      bytecodes.concat compile(statement)
      if i < statements.size - 1
        bytecodes.push [:discard]
      end
    end

    bytecodes
  end

  def compile_call sexp
    _, receiver, method_name, arglist = sexp
    bytecodes = []
    bytecodes.push [:start_call]

    if receiver
      bytecodes.concat compile(receiver)
    else
      bytecodes.push [:top]
    end
    bytecodes.push [:arg]

    bytecodes.push [:token] + sexp.source
    bytecodes.push [:result, method_name]
    bytecodes.push [:arg]
    
    bytecodes.concat compile(arglist)

    bytecodes.push [:call]
    bytecodes
  end

  def compile_arglist sexp
    _, *args = sexp
    bytecodes = []

    args.each do |arg|
      bytecodes.concat compile(arg)
      bytecodes.push [:arg]
    end

    bytecodes
  end

  def compile_lasgn sexp
    _, var_name, expression = sexp
    bytecodes = []
    bytecodes.push [:token] + sexp.source
    bytecodes.push [:start_var, var_name]
    bytecodes.concat compile(expression)
    bytecodes.push [:to_var, var_name]
    bytecodes
  end

  def compile_lvar sexp
    _, var_name = sexp
    [[:token] + sexp.source, [:from_var, var_name]]
  end

  def compile_if sexp
    _, condition, then_block, else_block = sexp
    bytecodes = []
    bytecodes.concat compile(condition)
    label_else = "else_#{sexp.source.join('_')}"
    label_endif = "endif_#{sexp.source.join('_')}"
    bytecodes.push [:goto_if_not, label_else]
    if then_block && then_block.source
      bytecodes.push [:position] + then_block.source
    end
    bytecodes.concat compile(then_block)
    bytecodes.push [:goto, label_endif]
    bytecodes.push [:label, label_else]
    if else_block && else_block.source
      bytecodes.push [:position] + else_block.source
    end
    bytecodes.concat compile(else_block)
    bytecodes.push [:label, label_endif]
    bytecodes
  end

  def compile_dstr sexp
    _, str, *strs_or_evstrs = sexp
    bytecodes = []
    bytecodes.push [:start_call]
    bytecodes.push [:result, str]
    bytecodes.push [:arg]
    bytecodes.push [:result, :<<]
    bytecodes.push [:arg]
    strs_or_evstrs.each do |str_or_evstr|
      bytecodes.concat compile(str_or_evstr)
      bytecodes.push [:arg]
    end
    bytecodes.push [:call]
    bytecodes
  end
end
