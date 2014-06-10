compile = (ruby_code) ->
  parser = Opal.Opal._scope.Parser.$new()
  sexp1 = parser.$parse Opal.BytecodeInterpreter.$RUNTIME_PRELUDE()
  sexp2 = parser.$parse ruby_code
  main = Opal.top
  compiler = Opal.AstToBytecodeCompiler.$new main
  bytecodes1 = compiler.$compile_program sexp1
  bytecodes1 = _.reject bytecodes1, (bytecode) ->
    bytecode[0] == 'position' || bytecode[0] == 'token'
  bytecodes2 = compiler.$compile_program sexp2
  bytecodes = bytecodes1.concat [['discard']], bytecodes2
  #for bytecode in bytecodes
  #  console.log bytecode.join(' ')
  bytecodes

module.exports =
  compile: compile
