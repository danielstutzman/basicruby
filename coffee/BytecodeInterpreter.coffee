class BytecodeInterpreter

  constructor: (bytecodes) ->
    @bytecodes   = bytecodes
    @interpreter = Opal.BytecodeInterpreter.$new Opal.top, bytecodes

    handler = @make_lambda((output) -> console.log('Output', output))
    @interpreter.$set_output_handler._p = handler # how to specify a block
    @interpreter.$set_output_handler()

  make_lambda: (func) ->
    Opal.top.$lambda._p = () ->
      result = func.apply(this, arguments)
      if result == null
        Opal.NIL
      else
        result
    Opal.top.$lambda.call(Opal.top)

  run: ->
    try
      @interpreter.$run()
    catch ruby_exception
      console.error ruby_exception.stack
      throw ruby_exception

module.exports = BytecodeInterpreter
