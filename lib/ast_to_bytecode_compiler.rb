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
      when :str
        if sexp.source # will be nil for "" literal
          [[:token] + sexp.source, [:result, sexp[1]]]
        else
          [[:result, sexp[1]]]
        end
      when :nil     then [[:token] + sexp.source, [:result, nil]]
      when :true    then [[:token] + sexp.source, [:result, true]]
      when :false   then [[:token] + sexp.source, [:result, false]]
      when :array   then compile_array sexp
      when :block   then compile_block sexp
      when :call    then compile_call sexp
      when :arglist then compile_arglist sexp
      when :paren   then compile sexp[1]
      when :lasgn   then compile_lasgn sexp
      when :lvar    then compile_lvar sexp
      when :if      then compile_if sexp
      when :dstr    then compile_dstr sexp
      when :evstr   then compile sexp[1]
      when :iter    then compile_iter sexp
      when :masgn   then compile_masgn sexp
      else no "s-exp with head #{sexp[0]}"
    end
  end

  def source statement
    if statement == nil
      [0, 0]
    elsif statement[0] == :block
      statement[1].source
    else
      statement.source
    end
  end

  def compile_array sexp
    _, *elements = sexp
    bytecodes = []
    bytecodes.push [:start_call]
    bytecodes.push [:result, []]
    bytecodes.push [:arg]
    bytecodes.push [:result, :push]
    bytecodes.push [:arg]
    bytecodes.push [:result, nil]
    bytecodes.push [:arg] # no block
    elements.each do |element|
      bytecodes.concat compile(element)
      bytecodes.push [:arg]
    end
    bytecodes.push [:pre_call]
    bytecodes.push [:call]
    bytecodes
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
    _, receiver, method_name, arglist, optional_iter = sexp
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
    bytecodes.push [:make_symbol]
    bytecodes.push [:arg]
    
    if optional_iter
      statement = optional_iter[2]
      block_label = "start_#{source(statement).join('_')}"
      bytecodes.concat compile(optional_iter)
      bytecodes.push [:make_proc, block_label]
    else
      bytecodes.push [:result, nil] # no block arg
    end
    bytecodes.push [:arg]

    bytecodes.concat compile(arglist)

    bytecodes.push [:pre_call]
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
    bytecodes.push [:start_vars, var_name]
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
    bytecodes.push [:result, nil]
    bytecodes.push [:arg] # no block
    strs_or_evstrs.each do |str_or_evstr|
      bytecodes.concat compile(str_or_evstr)
      bytecodes.push [:arg]
    end
    bytecodes.push [:pre_call]
    bytecodes.push [:call]
    bytecodes
  end

  def compile_iter sexp
    _, assignments, statement = sexp
    bytecodes = []

    label_after_return = "after_return_#{source(statement).join('_')}"
    bytecodes.push [:goto, label_after_return]

    start_label = "start_#{source(statement).join('_')}"
    bytecodes.push [:label, start_label]

    bytecodes.push [:args]
    if assignments.nil?
      bytecodes.push [:vars_from_env_except]
    elsif assignments[0] == :lasgn
      var_name = assignments[1]
      bytecodes.push [:vars_from_env_except, var_name]
      bytecodes.push [:to_vars, nil, var_name]
    elsif assignments[0] == :masgn
      if assignments[1][0] == :array
        var_names = assignments[1][1..-1].map do |lasgn|
          if lasgn[0] == :lasgn
            lasgn[1]
          else
            no "contents of :masgn's :array except :lasgn"
          end
        end
        bytecodes.push [:vars_from_env_except] + var_names
        bytecodes.push [:to_vars, nil] + var_names
      else
        no 'contents of :masgn besides :array'
      end
    else
      no 'assignments other than :lasgn and :masgn'
    end
    bytecodes.push [:discard] # since result of multi-assign is ignored

    bytecodes.concat compile(statement)
    bytecodes.push [:return]

    bytecodes.push [:label, label_after_return]

    bytecodes
  end

  def compile_masgn sexp
    _, to_array, from_expression = sexp
    if to_array[0] == :array
      var_names = to_array[1..-1].map do |lasgn|
        if lasgn[0] == :lasgn
          lasgn[1]
        else
          no "contents of :masgn's :array except :lasgn"
        end
      end
    else
      no 'masgn[1] except array' if to_array[0] != :array
    end

    bytecodes = []
    bytecodes.concat compile(from_expression)
    bytecodes.push [:to_vars, nil] + var_names
    bytecodes
  end
end
