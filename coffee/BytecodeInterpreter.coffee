class BytecodeInterpreter

  constructor: ->
    try
      @interpreter = Opal.BytecodeInterpreter.$new()
    catch e
      console.error e.stack
      throw e

  interpret: (bytecode) ->
    try
      @_nilToNull @interpreter.$interpret bytecode
    catch e
      if e.name == 'ProgramTerminated'
        # don't print out its stack trace
        throw e
      else
        console.error e.stack
        throw e

  visibleState: ->
    try
      map = @interpreter.$visible_state().map
      partialCalls: map.partial_calls
      numPartialCallExecuting: @_nilToNull map.num_partial_call_executing
      varsStack: map.vars_stack
      output: map.output
      acceptingInput: map.accepting_input
    catch e
      console.error e.stack
      throw e

  _nilToNull: (x) ->
    if x == Opal.NIL then null else x

  isAcceptingInput: ->
    try
      @interpreter['$is_accepting_input?']()
    catch e
      console.error e.stack
      throw e

  setInput: (text) ->
    try
      @interpreter.$set_input text
    catch e
      console.error e.stack
      throw e

  getStdout: ->
    try
      @interpreter['$get_stdout']()
    catch e
      console.error e.stack
      throw e

  getStderr: ->
    try
      @interpreter['$get_stderr']()
    catch e
      console.error e.stack
      throw e

  getStdoutAndStderr: ->
    try
      @interpreter['$get_stdout_and_stderr']()
    catch e
      console.error e.stack
      throw e

  undefineMethods: ->
    try
      @interpreter['$undefine_methods!']()
    catch e
      console.error e.stack
      throw e

module.exports = BytecodeInterpreter
