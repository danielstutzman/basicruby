ConsoleComponent      = require './ConsoleComponent.coffee'
InstructionsComponent = require './InstructionsComponent.coffee'
VariablesComponent    = require './VariablesComponent.coffee'
PartialCallsComponent = require './PartialCallsComponent.coffee'

POWER_SYMBOL   = '\u233d'
RIGHT_TRIANGLE = '\u25b6'
type           = React.PropTypes

DebuggerComponent = React.createClass

  displayName: 'DebuggerComponent'

  propTypes:
    isOn:          type.bool.isRequired
    buttons:       type.object
    instructions:  type.object
    interpreter:   type.object
    doCommand:     type.object.isRequired

  render: ->
    { br, button, div, label, span } = React.DOM

    div
      className: 'machine ' + (if @props.isOn then 'on ' else 'off ')

      div
        className: 'buttons'
        button
          className: 'step ' + (if @props.buttons?.breakpoint ==
            'NEXT_POSITION' && @props.buttons?.numStepsQueued >
            0 then 'active ' else '')
          onClick: => @props.doCommand.nextPosition()
          disabled: !@props.isOn || @props.buttons?.isDone
          "#{RIGHT_TRIANGLE} Step"
        button
          className: 'fast-forward ' + (if @props.buttons?.breakpoint ==
            'DONE' && @props.buttons?.numStepsQueued >
            0 then 'active ' else '')
          onClick: => @props.doCommand.run()
          disabled: !@props.isOn || @props.buttons?.isDone
          "#{RIGHT_TRIANGLE}#{RIGHT_TRIANGLE} Run"
        button
          className: 'power ' + (if @props.isOn then 'active ' else '')
          onClick: => @props.doCommand.togglePower()
          "#{POWER_SYMBOL} Power"

      label {}, 'Instructions'
      InstructionsComponent @props.instructions

      PartialCallsComponent @props.interpreter

      label {}, 'Variables'
      VariablesComponent @props.interpreter

      label {}, 'Input & Output'
      ConsoleComponent
        output: @props.interpreter?.output
        acceptingInput: @props.interpreter?.acceptingInput
        doInput: (text) => @props.doCommand.doInput text

      br { clear: 'all' }

module.exports = DebuggerComponent
