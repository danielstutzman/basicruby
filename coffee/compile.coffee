compile = (code) ->
  sexp = Opal.Opal.Parser.$new().$parse(code)
  return Opal.Object.__proto__.$block_to_pos_to_result(sexp)
module.exports = { compile: compile }
