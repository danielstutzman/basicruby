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
      compile_block_to_hash sexp
    else
      {}
    end
  end
  def compile_ruby_expression_to_bytecodes ruby_code
    parser = Opal::Parser.new
    sexp = parser.parse(ruby_code)
    compile_expression sexp
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

  def compile_block_to_hash sexp
    hash = {}
    head, tail = sexp[0], sexp[1..-1]
    assert head == :block

    poses = tail.map { |statement| statement_to_pos(statement) }
    assert poses.uniq == poses

    hash[:start] = poses.first

    tail.each_with_index do |statement, i|
      bytecodes = compile_expression statement

      next_pos = poses[i + 1]
      if next_pos
        bytecodes.push [:goto, next_pos]
      else
        bytecodes.push [:done]
      end

      pos = statement_to_pos statement
      hash[pos] = bytecodes
    end

    hash
  end

  def compile_expression sexp
    head, tail = sexp[0], sexp[1..-1]
    case head
      when :call  then compile_call tail
      when :int   then compile_int tail
      when :float then compile_float tail
      when :str   then compile_string tail
      when :nil   then compile_nil tail
      when :paren then compile_paren tail
      when :lasgn then compile_lasgn tail
      when :lvar  then compile_lvar tail
      else no "s-exp with head #{head}"
    end
  end
  def compile_call tail
    bytecodes = []
    receiver, method, arglist = tail

    bytecodes.push [:start_call]

    if receiver
      bytecodes.concat compile_expression(receiver)
    end
    bytecodes.push [:arg]

    assert arglist[0] == :arglist
    arglist[1..-1].each do |arg|
      bytecodes.concat compile_expression(arg)
      bytecodes.push [:arg]
    end

    bytecodes.push [:call, method]

    bytecodes
  end
  def compile_int tail
    assert tail.size == 1
    assert tail[0] == tail[0].to_i
    [[:int, tail[0]]]
  end
  def compile_float tail
    assert tail.size == 1
    assert tail[0] == tail[0].to_f
    [[:float, tail[0]]]
  end
  def compile_string tail
    assert tail.size == 1
    assert tail[0] == tail[0].to_s
    [[:string, tail[0]]]
  end
  def compile_nil tail
    assert tail == []
    [[:nil]]
  end
  def compile_paren tail
    assert tail.size == 1
    compile_expression tail[0]
  end
  def compile_lasgn tail
    assert tail.size == 2
    var_name, expression = tail
    compile_expression(expression) + [[:assign_to, var_name]]
  end
  def compile_lvar tail
    assert tail.size == 1
    [[:lookup_var, tail[0]]]
  end
end
