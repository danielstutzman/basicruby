type           = React.PropTypes

ConsoleComponent = React.createClass

  displayName: 'ConsoleComponent'

  propTypes:
    lines: type.string.isRequired

  componentDidUpdate: (prevProps, prevState) ->
    if @props.lines.split("\n").length != prevProps.lines.split("\n").length
      @_scrollConsole()

  _scrollConsole: ->
    $console = @refs.console.getDOMNode()
    $console.scrollTop = $console.scrollHeight

  render: ->
    { div, span } = React.DOM

    div
      className: 'console'
      ref: 'console'
      span
        className: 'before-cursor'
        @props.lines
      div
        className: 'cursor'

module.exports = ConsoleComponent
