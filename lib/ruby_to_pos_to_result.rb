class BasicRubyDoesntYetSupport < RuntimeError
end

class Compilation
  attr_accessor :output
  attr_accessor :_return
  def initialize(output, _return)
    @output = output
    @_return = _return
  end
end

def no(message)
  raise BasicRubyDoesntYetSupport.new(message)
end

def compile_expr(sexp)
  if sexp[0] == :call
    if sexp[1] == nil
      if sexp[2] == :puts
        if sexp[3] && sexp[3][0] == :arglist
          output = sexp[3][1..-1].map { |sexp|
            compilation = compile_expr(sexp)
            "#{compilation.output}#{compilation._return}\n"
          }.join
          _return = nil
          Compilation.new(output, _return)
        else
          no "puts method calls without :arglist"
        end
      else
        no "receiverless method calls besides puts"
      end
    else
      no "method calls with receivers"
    end
  elsif sexp[0] == :int
    Compilation.new('', sexp[1])
  elsif sexp[0] == :str
    Compilation.new('', sexp[1])
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
      output = compile_expr(sexp).output # ignore _return
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

  code = "puts 8\nputs(puts(4))\nputs 5"
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

  puts code_to_pos_to_result(code)
end
