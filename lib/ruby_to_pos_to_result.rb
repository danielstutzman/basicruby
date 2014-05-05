class BasicRubyDoesntYetSupport < RuntimeError
end

def no(message)
  raise BasicRubyDoesntYetSupport.new(message)
end

def literal_to_output(sexp)
  if sexp[0] == :int
    sexp[1].to_s + "\n"
  elsif sexp[0] == :str
    sexp[1] + "\n"
  else
    no "literal type #{sexp[0]}"
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
          no "puts method calls without :arglist"
        end
      else
        no "receiverless method calls besides puts"
      end
    else
      no "method calls with receivers"
    end
  else
    no "expression type #{sexp[0]}"
  end
end

def sexp_to_pos(sexp)
  if sexp.source
    sexp.source[0]
  else
    raise "Can't find source line for s-exp #{sexp.inspect}"
  end
end

def statements_to_pos_to_result(sexp)
  if sexp == nil
    parser = Opal::Parser.new
    block = parser.s(:block) # an empty block
    block_to_pos_to_result(block)
  elsif sexp[0] == :block
    block_to_pos_to_result(sexp)
  else
    parser = Opal::Parser.new
    block = parser.s(:block, sexp) # wrap with a block
    block_to_pos_to_result(block)
  end
end

def block_to_pos_to_result(sexp)
  if sexp[0] == :block
    poses = sexp[1..-1].map { |sexp| sexp_to_pos(sexp) } + [:finish]
    if poses.uniq != poses
      raise "Can't have more than one statement on a line"
    end

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
    no "block type #{sexp[0]}"
  end
end

def code_to_pos_to_result(code)
  parser = Opal::Parser.new
  sexp = parser.parse(code)
  statements_to_pos_to_result(sexp)
end 

if __FILE__ == $0
  send :require, 'opal' # avoid require being noticed by opal->js compiler

  parser = Opal::Parser.new
  compiler = Opal::Compiler.new

  code = "puts 3\nputs 4"
  p code

  sexp = parser.parse(code)
  if sexp
    compiler.scope = Opal::Nodes::ScopeNode.new(sexp, :stmt, compiler)
    sexp = parser.s(:top, sexp)
  else
    sexp = parser.s(:top)
  end
  p sexp

  processed = compiler.process(sexp)
  p processed

  fragments = processed.flatten
  p fragments

  result = fragments.map(&:code)
  puts "{\n#{result.join}\n}"

  puts code_to_pos_to_result("puts 3\nputs 4")
end
