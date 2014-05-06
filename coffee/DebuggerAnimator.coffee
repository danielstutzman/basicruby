BytecodeCompiler    = require './BytecodeCompiler.coffee'
BytecodeInterpreter = require './BytecodeInterpreter.coffee'
DebuggerComponent   = require './DebuggerComponent.coffee'

class DebuggerAnimator
  MILLIS_FOR_OUTPUT_DURING = 200
  MILLIS_FOR_OUTPUT_AFTER = 300

  constructor: (codeMirror) ->
    @codeMirror = codeMirror
    @props =
      state:        'OFF'
      pos:          null
      console:      ''
      instructions: ''
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
      @props.state        = 'ON'
      @props.instructions = @codeMirror.getValue()
      hash                = BytecodeCompiler.compile_ruby_code_to_hash \
                              @props.instructions
      @interpreter        = new BytecodeInterpreter hash
      @props.pos          = @interpreter.getPos()
      @props.console      = ''
    @_render()

  _handleStep: ->
    @interpreter.step()
    @props.pos = @interpreter.getPos()
    @_slowlyOutput @interpreter.getStepOutput(), (->)

  _slowlyOutput: (output, callback) ->
    outputNextLetter = (rest) =>
      nextLetter = rest[0]
      rest = rest[1..-1]
      @props.console += nextLetter
      @_render()

      #if nextLetter == "\n"
      #  $one('div.machine .console').scrollTop =
      #    $one('div.machine .console').scrollHeight
      if rest != ''
        window.setTimeout (-> outputNextLetter rest), millis_for_each_letter
      else
        callback()
    millis_for_each_letter = MILLIS_FOR_OUTPUT_DURING / (output.length || 1)
    outputNextLetter output

  _handleRun: ->
    doStep = =>
      if @interpreter.getPos() != null
        @interpreter.step()
        @props.pos = @interpreter.getPos()
        @_slowlyOutput @interpreter.getStepOutput(), doStep
    doStep()

  run: ->
    @_render()

module.exports = DebuggerAnimator
