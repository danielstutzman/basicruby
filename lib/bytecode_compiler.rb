class BytecodeCompiler
  def compile_ruby_program_to_hash ruby_code
    # expects Opal to already be required, so that the Opal compiler
    # won't pull it all in when compiling this file
    parser = Opal::Parser.new

    begin
      sexp = parser.parse(ruby_code)
    rescue RuntimeError => e
      # SyntaxErrors get thrown as RuntimeErrors when run with Racc gem
      if match = e.message.match(/(parse error(.*)):\(string\):([0-9]+)$/)
        raise SyntaxError.new "SyntaxError on line #{match[3]}: #{match[1]}"
      else
        raise
      end
    rescue SyntaxError => e
      # SyntaxErrors get thrown as SyntaxErrors when run with Opal's Racc
      raise
    end

    if sexp
      sexp = [:block, sexp] if sexp[0] != :block
      compile_block_to_hash sexp, nil
    else
      {}
    end
  end
  def compile_ruby_expression_to_bytecodes ruby_code
    parser = Opal::Parser.new
    sexp = parser.parse(ruby_code)
    compile_expression sexp, nil, false
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

  def statement_to_pos sexp
    assert sexp.source
    "#{sexp.source[0]},#{sexp.source[1]}"
  end

  def compile_block_to_hash sexp, pos_after_block
    hash = {}
    head, tail = sexp[0], sexp[1..-1]
    assert head == :block

    poses = tail.map { |statement| statement_to_pos(statement) }
    assert poses.uniq == poses
    hash[:start] = poses.first

    tail.each_with_index do |statement, i|
      next_pos = poses[i + 1] || pos_after_block

      bytecodes = compile_expression statement, next_pos, true

      case statement[0]
        when :if
          true_block = statement[2]
          if true_block
            true_block = [:block, true_block] if true_block[0] != :block
            true_hash = compile_block_to_hash true_block, next_pos
            true_hash.delete :start
            hash = hash.merge true_hash # to keep lines in order
          end
          else_block = statement[3]
          if else_block
            else_block = [:block, else_block] if else_block[0] != :block
            else_hash = compile_block_to_hash else_block, next_pos
            else_hash.delete :start
            hash = hash.merge else_hash # to keep lines in order
          end
        when :call, :int, :float, :str, :nil, :paren, :lasgn,
             :lvar, :dstr, :true, :false
          bytecodes.push [:goto, next_pos]
        else
          no "statement s-exp with head #{statement[0]}"
      end

      pos = statement_to_pos statement
      hash[pos] = bytecodes
    end

    hash
  end

  def compile_expression sexp, next_pos, is_statement
    head, tail = sexp[0], sexp[1..-1]
    case head
      when :call  then compile_call tail,   next_pos, is_statement
      when :int   then compile_int tail,    next_pos, is_statement
      when :float then compile_float tail,  next_pos, is_statement
      when :str   then compile_string tail, next_pos, is_statement
      when :nil   then compile_nil tail,    next_pos, is_statement
      when :paren then compile_paren tail,  next_pos, is_statement
      when :lasgn then compile_lasgn tail,  next_pos, is_statement
      when :lvar  then compile_lvar tail,   next_pos, is_statement
      when :dstr  then compile_dstr tail,   next_pos, is_statement
      when :if    then compile_if tail,     next_pos, is_statement
      when :true  then compile_true tail,   next_pos, is_statement
      when :false then compile_false tail,  next_pos, is_statement
      else no "s-exp with head #{head}"
    end
  end
  def compile_call tail, next_pos, is_statement
    bytecodes = []
    receiver, method, arglist = tail

    bytecodes.push [:start_call]

    if receiver
      bytecodes.concat compile_expression(receiver, next_pos, false)
    end
    bytecodes.push [:arg]

    assert arglist[0] == :arglist
    arglist[1..-1].each do |arg|
      bytecodes.concat compile_expression(arg, next_pos, false)
      bytecodes.push [:arg]
    end

    bytecodes.push [:call, method]

    bytecodes
  end
  def compile_int tail, next_pos, is_statement
    assert tail.size == 1
    assert tail[0] == tail[0].to_i
    [[:int, tail[0]]]
  end
  def compile_float tail, next_pos, is_statement
    assert tail.size == 1
    assert tail[0] == tail[0].to_f
    [[:float, tail[0]]]
  end
  def compile_string tail, next_pos, is_statement
    assert tail.size == 1
    assert tail[0] == tail[0].to_s
    [[:string, tail[0]]]
  end
  def compile_nil tail, next_pos, is_statement
    assert tail == []
    [[:nil]]
  end
  def compile_paren tail, next_pos, is_statement
    assert tail.size == 1
    compile_expression tail[0], next_pos, false
  end
  def compile_lasgn tail, next_pos, is_statement
    assert tail.size == 2
    var_name, expression = tail
    compile_expression(expression, next_pos, false) +
      [[:assign_to, var_name]]
  end
  def compile_lvar tail, next_pos, is_statement
    assert tail.size == 1
    [[:lookup_var, tail[0]]]
  end
  def compile_dstr tail, next_pos, is_statement
    bytecodes = []
    bytecodes.push [:start_call]
    bytecodes.push [:arg] # no receiver
    if tail[0] != ''
      bytecodes.push [:string, tail[0]]
      bytecodes.push [:arg]
    end
    tail[1..-1].each do |arg|
      case arg[0]
      when :evstr
        assert arg.size == 2
        bytecodes.concat compile_expression(arg[1], next_pos, false)
        bytecodes.push [:arg]
      when :str
        assert arg.size == 2
        bytecodes.push [:string, arg[1]]
        bytecodes.push [:arg]
      else
        no "s-exp of type #{arg[0]} in s-exp type :dstr"
      end
    end
    bytecodes.push [:call, :__STRINTERP]
    bytecodes
  end
  def compile_if tail, next_pos, is_statement
    no 'if inside expression' if !is_statement

    bytecodes = []
    condition = tail[0]
    bytecodes.concat compile_expression(condition, next_pos, false)

    true_block = tail[1]
    if true_block # if not an empty if condition
      true_block = [:block, true_block] if true_block[0] != :block
      true_pos = true_block[1].source.join(',')
    else
      true_pos = next_pos
    end

    else_block = tail[2]
    if else_block # if not missing the else, and else block isn't empty
      else_block = [:block, else_block] if else_block[0] != :block
      else_pos = else_block[1].source.join(',')
    else
      else_pos = next_pos
    end

    bytecodes.push [:if_goto, true_pos, else_pos]

    bytecodes
  end
  def compile_true tail, next_pos, is_statement
    assert tail == []
    [[:bool, true]]
  end
  def compile_false tail, next_pos, is_statement
    assert tail == []
    [[:bool, false]]
  end
end
