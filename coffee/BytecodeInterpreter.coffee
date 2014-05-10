class BytecodeInterpreter

  constructor: (bytecodes) ->
    try
      @bytecodes   = bytecodes
      @interpreter = Opal.BytecodeInterpreter.$new bytecodes
    catch e
      console.error e.stack
      throw e

  run: ->
    try
      @interpreter.$run()
    catch e
      console.error e.stack
      throw e

  have_more_bytecodes: ->
    try
      @interpreter['$have_more_bytecodes?']()
    catch e
      console.error e.stack
      throw e

  run_next_bytecode: ->
    try
      @interpreter.$run_next_bytecode()
    catch e
      console.error e.stack
      throw e

  vars: ->
    try
      @interpreter['$state']()['$vars']()
    catch e
      console.error e.stack
      throw e

module.exports = BytecodeInterpreter
