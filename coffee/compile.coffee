compile = (code) ->
  try
    sexp = Opal.Opal.Parser.$new().$parse(code)
    return Opal.Object.__proto__.$statements_to_pos_to_result(sexp)
  catch e
    console.error e.stack
    throw e

module.exports = { compile: compile }
