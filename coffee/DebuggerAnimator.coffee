BytecodeCompiler    = require './BytecodeCompiler.coffee'
BytecodeInterpreter = require './BytecodeInterpreter.coffee'
DebuggerComponent   = require './DebuggerComponent.coffee'

class DebuggerAnimator
  MILLIS_FOR_BOLD                  = 300
  MILLIS_FOR_OUTPUT_DURING         = 200
  MILLIS_FOR_OUTPUT_AFTER          = 300
  MILLIS_FOR_UNBOLD                = 500
  MILLIS_FOR_SCROLLED_INSTRUCTIONS = 500

  constructor: (codeMirror) ->
    @codeMirror = codeMirror
    @props =
      state:         'OFF'
      pos:           null
      console:       ''
      instructions:  ''
      highlightLine: false
      vars:          {}
      doCommand:
        power: => @_handlePower.apply this, arguments
        step:  => @_handleStep.apply  this, arguments
        run:   => @_handleRun.apply   this, arguments
    @interpreter = null
    @$div = document.querySelector 'div.debugger'

  _render: ->
    React.renderComponent DebuggerComponent(@props), @$div

  _handlePower: ->
    if @props.state == 'ON'
      @props.state        = 'OFF'
      @props.instructions = ''
      @props.console      = ''
      @interpreter        = null
    else
      @props.state   = 'ON'
      @props.console = ''
      try
        hash = BytecodeCompiler.compile_ruby_code_to_hash @codeMirror.getValue()
      catch e
        if e.name == 'SyntaxError'
          @props.console = "SyntaxError: #{e.message}"
        else if e.name == 'DebuggerDoesntYetSupport'
          @props.console = "DebuggerDoesntYetSupport: #{e.message}"
        else
          throw e
      if hash
        @props.instructions = @codeMirror.getValue()
        @interpreter        = new BytecodeInterpreter hash
        @props.pos          = @interpreter.getPos()
      else
        @props.pos = null
    @_render()

  _handleStep: (callback) ->
    @_doWholeStep (->)

  _doWholeStep: (callback) ->
    @_addBold =>
      @_doJustStep =>
        @_removeBold =>
          @_scrollInstructions =>
            callback()

  _doJustStep: (callback) ->
    @interpreter.step()
    @props.vars = @interpreter.getVars()
    # @props.pos = @interpreter.getPos() # wait to show this
    @_slowlyOutput @interpreter.getStepOutput(), =>
      callback()

  _addBold: (callback) ->
    @props.highlightLine = true
    @_render()
    window.setTimeout callback, MILLIS_FOR_BOLD

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

  _removeBold: (callback) ->
    @props.highlightLine = false
    @_render()
    window.setTimeout callback, MILLIS_FOR_UNBOLD

  _scrollInstructions: (callback) ->
    @props.pos = @interpreter.getPos()
    if @props.pos == null
      @props.instructions = ''
    @_render()
    window.setTimeout callback, MILLIS_FOR_SCROLLED_INSTRUCTIONS

  _handleRun: ->
    doStepIfThereIsOne = =>
      if @interpreter.getPos() != null
        @_doWholeStep doStepIfThereIsOne
    doStepIfThereIsOne()

  run: ->
    @_render()

module.exports = DebuggerAnimator
