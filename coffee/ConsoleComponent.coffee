type           = React.PropTypes
ENTER_KEY      = 13

MILLIS_FOR_OUTPUT_CHAR = 10

ConsoleComponent = React.createClass

  displayName: 'ConsoleComponent'

  propTypes:
    output: type.array
    acceptingInput: type.bool
    doInput: type.func.isRequired
    animationFinished: type.func.isRequired

  getInitialState: ->
    numEmittedOutputChars: 0
    numReceivedOutputChars: 0

  shouldComponentUpdate: (nextProps, nextState) ->
    if nextProps.output?.length == @props.output?.length &&
       nextProps.acceptingInput == @props.acceptingInput &&
       nextState.numEmittedOutputChars == @state.numEmittedOutputChars
      nextProps.animationFinished()
      false
    else
      true

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
      window.setTimeout outputOneMoreChar, MILLIS_FOR_OUTPUT_CHAR
      @_scrollConsole()
    else
      @props.animationFinished()

  _scrollConsole: ->
    $console = @refs.console.getDOMNode()
    $console.scrollTop = $console.scrollHeight

  render: ->
    { div, input, label, span } = React.DOM

    numCharsToEmit = @state.numEmittedOutputChars

    div {},
      label {}, 'Input & Output'
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
