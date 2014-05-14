type           = React.PropTypes
ENTER_KEY      = 13

ConsoleComponent = React.createClass

  displayName: 'ConsoleComponent'

  propTypes:
    output: type.array
    acceptingInput: type.bool
    doInput: type.func

  getInitialState: ->
    numEmittedOutputChars: 0
    numReceivedOutputChars: 0

  componentWillReceiveProps: (nextProps) ->
    if nextProps.output
      numChars = 0
      for text in nextProps.output
        numChars += text.length
      @setState numReceivedOutputChars: numChars
    else
      @setState numEmittedOutputChars: 0, numReceivedOutputChars: 0

  componentDidUpdate: (prevProps, prevState) ->
    if @props.acceptingInput && !prevProps.acceptingInput
      @refs.stdin.getDOMNode().focus()
    if @state.numEmittedOutputChars < @state.numReceivedOutputChars
      outputOneMoreChar = =>
        @setState numEmittedOutputChars: @state.numEmittedOutputChars + 1
      window.setTimeout outputOneMoreChar, 10
    @_scrollConsole()

  _scrollConsole: ->
    $console = @refs.console.getDOMNode()
    $console.scrollTop = $console.scrollHeight

  render: ->
    { div, input, span } = React.DOM

    numCharsToEmit = @state.numEmittedOutputChars

    div
      className: 'console'
      ref: 'console'
      span
        className: 'before-cursor'
        _.map (@props.output || []), (text) ->
          if numCharsToEmit > 0
            substring = text.substring 0, numCharsToEmit
            numCharsToEmit -= substring.length
            substring
      if @props.acceptingInput
        input
          ref: 'stdin'
          type: 'text'
          className: 'stdin'
          onKeyPress: (e) =>
            if e.keyCode == 13
              @props.doInput "#{e.target.value}\n"
      else
        div
          className: 'cursor'

module.exports = ConsoleComponent
