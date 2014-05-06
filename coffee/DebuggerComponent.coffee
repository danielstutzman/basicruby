RIGHT_ARROW    = '\u2192'
POWER_SYMBOL   = '\u233d'
RIGHT_TRIANGLE = '\u25b6'
type           = React.PropTypes

DebuggerComponent = React.createClass

  displayName: 'DebuggerComponent'

  propTypes:
    state:        type.string.isRequired
    pos:          type.string
    console:      type.string.isRequired
    instructions: type.string.isRequired
    doCommand:    type.object.isRequired

  _instructionsToHtml: ->
    { br, div } = React.DOM

    lines = @props.instructions.split("\n")
    html = [ br { key: 1 } ] # blank line at beginning
    line_num = 1
    for line in lines
      html.push div
        key: "num#{line_num}"
        className: "num _#{line_num}"
        line_num
      html.push div
        key: "code#{line_num}"
        className: "code _#{line_num}"
        line
      line_num += 1
    html.push br { key: 2, clear: 'all' }
    html.push br { key: 3 }
    html

  render: ->
    { br, button, div, label, span } = React.DOM

    div
      className:
        'machine ' +
        (@props.state == 'OFF' && 'off ' || '') +
        (@props.state != 'OFF' && 'on ' || '')

      div { className: 'buttons' },
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
        div { className: 'instructions' },
          div { className: 'pointer' }, RIGHT_ARROW
          div { className: 'content' },
            @_instructionsToHtml()

      label {}, 'Input & Output'
        div { className: 'console' },
          span { className: 'before-cursor' },
            @props.console
          div { className: 'cursor' }

      br { clear: 'all' }

module.exports = DebuggerComponent
