class Lexer
  def build_start_pos_to_end_pos code
    start_pos_to_end_pos = {}

    lexer = Opal::Lexer.new code, '(eval)'
    parser = Opal::Parser.new
    parser.instance_variable_set :@lexer, lexer
    parser.instance_variable_set :@file, '(eval)'
    parser.instance_variable_set :@scopes, []
    parser.push_scope :block
    lexer.parser = parser

    while true
      token_symbol, value = parser.next_token
      break if token_symbol == false

      if token_symbol == :tINTEGER ||
         token_symbol == :tFLOAT
        excerpt = lexer.scanner.matched
      else
        excerpt = value[0]
      end
      start_pos = value[1]
      end_pos = value[1].clone
      end_pos[1] += excerpt.length
      start_pos_to_end_pos[start_pos] = end_pos
    end
    start_pos_to_end_pos
  end
end

if __FILE__ == $0
  send :require, 'opal'
  p Lexer.build_start_pos_to_end_pos('puts 3')
end
