class BytecodeCompiler
  def compile(ruby_code)
    # expects Opal to already be required, so that the Opal compiler
    # won't pull it all in when compiling this file
    parser = Opal::Parser.new
    sexp = parser.parse(ruby_code)
    compile_expression sexp
  end

  private

  class AssertionFailed < RuntimeError
  end

  def assert bool
    raise AssertionFailed if !bool
  end
  def compile_expression sexp
    head, tail = sexp[0], sexp[1..-1]
    case head
      when :call then compile_call tail
      when :int  then compile_int tail
      else no "unknown s-exp head #{head}"
    end
  end
  def compile_call tail
    bytecode = []
    receiver, method, arglist = tail

    assert arglist[0] == :arglist
    arglist[1..-1].each do |arg|
      bytecode.concat compile_expression(arg)
      bytecode.push [:arg]
    end

    if receiver
      bytecode.push compile_expression(receiver)
    end

    bytecode.push [:call, method]

    bytecode
  end
  def compile_int tail
    assert tail.size == 1
    assert tail[0] == tail[0].to_i
    [[:int, tail[0]]]
  end
end
