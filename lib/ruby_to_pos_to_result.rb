def literal_to_output(sexp)
  if sexp[0] == :int
    sexp[1].to_s + "\n"
  elsif sexp[0] == :str
    sexp[1] + "\n"
  else
    raise "Was expecting :int or :str"
  end
end
def expr_to_output(sexp)
  if sexp[0] == :call
    if sexp[1] == nil
      if sexp[2] == :puts
        if sexp[3] && sexp[3][0] == :arglist
          sexp[3][1..-1].map { |sexp|
            literal_to_output(sexp)
          }.join
        else
          raise "Was expecting arglist"
        end
      else
        raise "Can only call puts method"
      end
    else
      raise "Can't call methods yet"
    end
  else
    raise "Unknown sexp #{sexp[0]}"
  end
end
def sexp_to_pos(sexp)
  sexp.source[0]
end
def block_to_pos_to_result(sexp)
  if sexp[0] == :block
    poses = sexp[1..-1].map { |sexp| sexp_to_pos(sexp) } + [:finish]

    pos_to_result = {}
    sexp[1..-1].each_with_index do |sexp, i|
      pos = sexp_to_pos(sexp)
      output = expr_to_output(sexp)
      result = { output: output, next: poses[i + 1] }
      pos_to_result[pos] = result
    end
    pos_to_result[:start] = poses[0]
    pos_to_result
  else
    raise "Unknown sexp #{sexp[0]}"
  end
end
def code_to_pos_to_result(code)
  parser = Opal::Parser.new
  sexp = parser.parse(code)
  block_to_pos_to_result(sexp)
end 

if __FILE__ == $0
  send :require, 'opal' # avoid require being noticed by opal->js compiler

  parser = Opal::Parser.new
  compiler = Opal::Compiler.new

  code = "puts 3\nputs 4\n"
  p code
  sexp = parser.parse(code)
  compiler.scope = Opal::Nodes::ScopeNode.new(sexp, :stmt, compiler)
  sexp = parser.s(:top, sexp)
  p sexp
  processed = compiler.process(sexp)
  p processed
  fragments = processed.flatten
  p fragments
  result = fragments.map(&:code)
  puts "{\n#{result.join}\n}"

  puts code_to_pos_to_result("puts 3\nputs 4\n")
end
