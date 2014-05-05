compile = (code) ->
  try
    sexp = Opal.Opal.Parser.$new().$parse(code)
    hash = Opal.Object.__proto__.$statements_to_pos_to_result(sexp)
  catch ruby_exception
    hash =
      map:
        start: 1
        1:
          map:
            output: "#{ruby_exception.name}: #{ruby_exception.message}"
            next: 'finish'
  hash

module.exports = { compile: compile }
