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
    elsif sexp[0] == :masgn
      position = [[:position] + sexp[1][1].source]
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
    elsif statement[0] == :masgn
      statement[1][1].source
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
      if source(statement)
        bytecodes.push [:position] + source(statement)
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

    splat_num = nil
    optional_block = nil
    min_num_args = max_num_args = 0
    if assignments.nil?
      var_names = []
    elsif assignments[0] == :lasgn
      min_num_args = max_num_args = 1
      var_names = [assignments[1]]
    elsif assignments[0] == :masgn
      if assignments[1][0] == :array
        i = -1
        var_names = assignments[1][1..-1].map do |part|
          i += 1
          if part[0] == :lasgn
            min_num_args += 1
            max_num_args += 1
            part[1]
          elsif part[0] == :splat && part[1][0] == :lasgn
            max_num_args = nil # no maximum
            splat_num = i
            part[1][1]
          elsif part[0] == :block
            min_num_args -= (part.size - 1)
            optional_block = part
            nil
          else
            no "contents of :masgn's :array except " +
              " :lasgn, :splat :lasgn, or :block"
          end
        end
        var_names = var_names.compact
      else
        no 'contents of :masgn besides :array'
      end
    else
      no 'assignments other than :lasgn and :masgn'
    end
    bytecodes.push [:args, min_num_args, max_num_args]
    bytecodes.push [:vars_from_env_except] + var_names
    bytecodes.push [:to_vars, splat_num] + var_names
    bytecodes.push [:discard] # since result of multi-assign is ignored

    if optional_block
      labels = (0..var_names.size).map do |i|
        "param_defaults_#{source(statement).join('_')}_#{i}"
      end
      bytecodes.push [:goto_param_defaults] + labels
      labels.each_with_index do |label, i|
        bytecodes.push [:label, label]
        if i < labels.size - 1
          bytecodes.concat compile(optional_block[i + 1])
          bytecodes.push [:discard] # since result of assignment is ignored
        end
      end
    end

    bytecodes.concat compile(statement)
    bytecodes.push [:return]

    bytecodes.push [:label, label_after_return]

    bytecodes
  end

  def compile_masgn sexp
    _, to_array, from_expression = sexp
    bytecodes = []
    splat_num = nil
    if to_array[0] == :array
      i = -1
      var_names = to_array[1..-1].map do |lasgn|
        i += 1
        if lasgn[0] == :lasgn
          bytecodes.push [:token] + lasgn.source
          bytecodes.push [:start_var, lasgn[1]]
          lasgn[1]
        elsif lasgn[0] == :splat && lasgn[1][0] == :lasgn
          bytecodes.push [:token] + lasgn[1].source
          bytecodes.push [:start_var, lasgn[1][1]]
          splat_num = i
          lasgn[1][1]
        else
          no "contents of :masgn's :array except :lasgn or :splat :lasgn"
        end
      end
    else
      no 'masgn[1] except array' if to_array[0] != :array
    end

    bytecodes.concat compile(from_expression)
    bytecodes.push [:to_vars, splat_num] + var_names
    bytecodes
  end
end
