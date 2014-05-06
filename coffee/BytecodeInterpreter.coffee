class BytecodeInterpreter

  constructor: (hash) ->
    @hash        = hash
    @interpreter = Opal.BytecodeInterpreter.$new Opal.top, hash

  getPos:    ->
    pos = @interpreter.$pos()
    if pos == Opal.NIL then null else pos

  getOutput: ->
    @interpreter.$output()

  step: ->
    try
      @interpreter.$step()
    catch ruby_exception
      console.error ruby_exception.stack
      throw ruby_exception

  run: ->
    try
      @interpreter.$run()
    catch ruby_exception
      console.error ruby_exception.stack
      throw ruby_exception

module.exports = BytecodeInterpreter
