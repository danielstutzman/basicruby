class BytecodeSpool

  constructor: (bytecodes) ->
    try
      @spool = Opal.BytecodeSpool.$new bytecodes
    catch e
      console.error e.stack
      throw e

  visibleState: ->
    try
      map = @spool.$visible_state().map
      breakpoint:     map.breakpoint
      numStepsQueued: map.num_steps_queued
      isDone:         map.is_done
    catch e
      console.error e.stack
      throw e

  queueRunUntil: (breakpoint) ->
    try
      @spool.$queue_run_until breakpoint
    catch e
      console.error e.stack
      throw e

  getNextBytecode: ->
    try
      result = @spool.$get_next_bytecode()
      if result == Opal.NIL then null else result
    catch e
      console.error e.stack
      throw e

  isDone: ->
    try
      @spool['$is_done?']()
    catch e
      console.error e.stack
      throw e

  terminateEarly: ->
    try
      @spool['$terminate_early']()
    catch e
      console.error e.stack
      throw e

  doCommand: ->
    try
      @spool['$do_command'].apply @spool, arguments
    catch e
      console.error e.stack
      throw e

module.exports = BytecodeSpool
