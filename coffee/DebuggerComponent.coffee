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
    state:         type.string.isRequired
    pos:           type.string
    console:       type.string.isRequired
    instructions:  type.string.isRequired
    doCommand:     type.object.isRequired
    vars:          type.object.isRequired
    partial_calls: type.array.isRequired
    num_partial_call_executing: type.number
    highlighted_range: type.array

  render: ->
    { br, button, div, label, span } = React.DOM

    div
      className:
        'machine ' +
        (@props.state == 'OFF' && 'off ' || '') +
        (@props.state != 'OFF' && 'on ' || '')

      div
        className: 'buttons'
        button
          className: 'step'
          onClick: => @props.doCommand.step()
          disabled: @props.state == 'OFF' || @props.pos == null
          "#{RIGHT_TRIANGLE} Step"
        button
          className: 'fast-forward'
          onClick: => @props.doCommand.run()
          disabled: @props.state == 'OFF' || @props.pos == null
          "#{RIGHT_TRIANGLE}#{RIGHT_TRIANGLE} Run"
        button
          className: 'power ' +
            (@props.state != 'OFF' && 'active ' || '')
          onClick: => @props.doCommand.power()
          "#{POWER_SYMBOL} Power"

      label {}, 'Instructions'
      InstructionsComponent
        pos: @props.pos
        instructions: @props.instructions
        highlighted_range: @props.highlighted_range

      PartialCallsComponent
        partial_calls: @props.partial_calls
        num_partial_call_executing: @props.num_partial_call_executing

      label {}, 'Variables'
      VariablesComponent
        vars: @props.vars

      label {}, 'Input & Output'
      ConsoleComponent
        lines: @props.console

      br { clear: 'all' }

module.exports = DebuggerComponent
