compile = (ruby_code) ->
  parser = Opal.Opal._scope.Parser.$new()
  sexp = parser.$parse ruby_code
  main = Opal.top
  compiler = Opal.AstToBytecodeCompiler.$new main
  compiler.$compile sexp

module.exports =
  compile: compile
