dump = (sexp, level) ->
  out = ''
  for i in [0..level]
    out += '  '
  out += sexp.array[0]
  for child in sexp.array
    if typeof child == 'string'
      out += ' ' + child
  console.log out
  for child in sexp.array
    if child.array
      dump child, level + 1

compile = (ruby_code) ->
  parser = Opal.Opal._scope.Parser.$new()
  sexp1 = parser.$parse Opal.BytecodeInterpreter.$RUNTIME_PRELUDE()
  sexp2 = parser.$parse ruby_code
  #dump sexp2, 0

  main = Opal.top
  compiler = Opal.AstToBytecodeCompiler.$new main
  bytecodes1 = compiler.$compile_program 'runtime', sexp1
  bytecodes1 = _.reject bytecodes1, (bytecode) ->
    bytecode[0] == 'position' || bytecode[0] == 'token'
  bytecodes2 = compiler.$compile_program 'user', sexp2
  #for bytecode in bytecodes2
  #  console.log bytecode.join(' ')
  bytecodes = bytecodes1.concat [['discard']], bytecodes2
  bytecodes

module.exports =
  compile: compile
