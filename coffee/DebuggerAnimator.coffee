BytecodeCompiler    = require './BytecodeCompiler.coffee'
BytecodeInterpreter = require './BytecodeInterpreter.coffee'
DebuggerComponent   = require './DebuggerComponent.coffee'

class DebuggerAnimator

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
      @props.state = 'OFF'
      @props.instructions = ''
      @interpreter = null
    else
      @props.state        = 'ON'
      @props.instructions = @codeMirror.getValue()
      hash                = BytecodeCompiler.compile_ruby_code_to_hash \
                              @props.instructions
      @interpreter        = new BytecodeInterpreter hash
      @props.pos          = @interpreter.getPos()
      @props.output       = @interpreter.getOutput()
    @_render()

  _handleStep: ->
    @interpreter.step()
    @props.pos    = @interpreter.getPos()
    @props.output = @interpreter.getOutput()
    @_render()

  _handleRun: ->
    @interpreter.run()
    @props.pos    = @interpreter.getPos()
    @props.output = @interpreter.getOutput()
    @_render()

  run: ->
    @_render()

module.exports = DebuggerAnimator
