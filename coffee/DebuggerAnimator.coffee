AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
DebuggerComponent     = require './DebuggerComponent.coffee'

class DebuggerAnimator
  MILLIS_FOR_BOLD                  = 300
  MILLIS_FOR_OUTPUT_DURING         = 200
  MILLIS_FOR_OUTPUT_AFTER          = 300
  MILLIS_FOR_UNBOLD                = 500
  MILLIS_FOR_SCROLLED_INSTRUCTIONS = 500
  MILLIS_FOR_PARTIAL_CALL_UPDATE   = 500

  constructor: (codeMirror) ->
    @codeMirror = codeMirror
    @props =
      state:         'OFF'
      pos:           null
      console:       ''
      instructions:  ''
      highlightLine: false
      vars:          {}
      partial_calls: []
      doCommand:
        power: => @_handlePower.apply this, []
        step:  => @_handleStep.apply  this, []
        run:   => @_handleRun.apply   this, []
    @interpreter = null
    @$div = document.querySelector 'div.debugger'
    @last_output_length = 0

  _render: ->
    React.renderComponent DebuggerComponent(@props), @$div

  _handlePower: ->
    if @props.state == 'ON'
      @props.state        = 'OFF'
      @props.instructions = ''
      @props.console      = ''
      @props.vars         = {}
      @interpreter        = null
    else
      @props.state   = 'ON'
      @props.console = ''
      try
        code = @codeMirror.getValue()
        bytecodes = AstToBytecodeCompiler.compile code
      catch e
        if e.name == 'SyntaxError'
          @props.console = "SyntaxError: #{e.message}"
        else if e.name == 'DebuggerDoesntYetSupport'
          @props.console = "DebuggerDoesntYetSupport: #{e.message}"
        else
          throw e
      if bytecodes
        @props.instructions = @codeMirror.getValue()
        @interpreter = new BytecodeInterpreter bytecodes
        @props.vars = @interpreter.vars()
        @_handleStep() # run step until the first position
    @_render()

  _handleStep: ->
    @_doStep null

  _doStep: (callback) ->
    while @interpreter.have_more_bytecodes()
      bytecode = @interpreter.run_next_bytecode()
      switch bytecode[0]
        when 'start_call', 'arg'
          @props.partial_calls = @interpreter.partial_calls()
          @_render()
          window.setTimeout (=> @_doStep(callback)),
            MILLIS_FOR_PARTIAL_CALL_UPDATE
          return
        when 'to_var'
          @props.vars = @interpreter.vars()
          @_render()
        when 'position'
          # only stop if we're going from one line to another,
          # not for an inline if expression like "if x then y else z end"
          if !@props.pos || "#{bytecode[1]}" != @props.pos.split(',')[0]
            @props.pos = "#{bytecode[1]},#{bytecode[2]}"
            @_render()
            window.setTimeout callback, 300 if callback
            return
        when 'call'
          @props.partial_calls = @interpreter.partial_calls()
          if window.$output_to_stdout &&
             window.$output_to_stdout.length > @last_output_length
            new_output =
              window.$output_to_stdout.slice(@last_output_length).join('')
            @last_output_length = window.$output_to_stdout.length
            @_slowlyOutput new_output, (=> @_doStep(callback))
            return
          else
            @_render()

    if !@interpreter.have_more_bytecodes()
      @props.pos = null
      @_render()

  _slowlyOutput: (output, callback) ->
    outputNextLetter = (rest) =>
      if rest != ''
        nextLetter = rest[0]
        rest = rest[1..-1]
        @props.console += nextLetter
        @_render()

        window.setTimeout (-> outputNextLetter rest), millis_for_each_letter
      else
        callback()
    millis_for_each_letter = MILLIS_FOR_OUTPUT_DURING / (output.length || 1)
    outputNextLetter output

  _handleRun: ->
    doStepIfThereIsOne = =>
      @_doStep =>
        if @interpreter.have_more_bytecodes()
          doStepIfThereIsOne()
    doStepIfThereIsOne()

  run: ->
    @_render()

module.exports = DebuggerAnimator
