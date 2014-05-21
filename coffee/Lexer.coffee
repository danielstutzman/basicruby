build_start_pos_to_end_pos = (ruby_code) ->
  try
    lexer = Opal.Lexer.$new()
    lexer.$build_start_pos_to_end_pos ruby_code
  catch e
    console.error e.stack
    throw e

build_line_start_pos_to_end_pos = (ruby_code) ->
  try
    lexer = Opal.Lexer.$new()
    lexer.$build_line_start_pos_to_end_pos ruby_code
  catch e
    console.error e.stack
    throw e

module.exports =
  build_start_pos_to_end_pos: build_start_pos_to_end_pos
  build_line_start_pos_to_end_pos: build_line_start_pos_to_end_pos
