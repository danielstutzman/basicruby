type           = React.PropTypes
ENTER_KEY      = 13

MILLIS_FOR_OUTPUT_CHAR = 10

ConsoleComponent = React.createClass

  displayName: 'ConsoleComponent'

  propTypes:
    output: type.array
    isConsoleFakeSelected: type.bool.isRequired
    pendingStdin: type.string
    doChangeInput: type.func.isRequired
    doSubmitInput: type.func.isRequired
    animationFinished: type.func.isRequired

  getInitialState: ->
    numEmittedOutputChars: 0
    numReceivedOutputChars: 0

  shouldComponentUpdate: (nextProps, nextState) ->
    if nextProps.output?.length == @props.output?.length &&
       nextProps.pendingStdin == @props.pendingStdin &&
       nextState.numEmittedOutputChars == @state.numEmittedOutputChars &&
       nextProps.isConsoleFakeSelected == @props.isConsoleFakeSelected
      nextProps.animationFinished()
      false
    else
      true

  componentWillReceiveProps: (nextProps) ->
    if nextProps.output
      numChars = 0
      for pair in nextProps.output
        numChars += pair[1].length
      @setState numReceivedOutputChars: numChars
    else
      @setState numEmittedOutputChars: 0, numReceivedOutputChars: 0

  componentDidUpdate: (prevProps, prevState) ->
    if @props.pendingStdin != prevProps.pendingStdin &&
       @props.pendingStdin != null
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
        className: 'console ' +
          (if @props.isConsoleFakeSelected then 'fake-selected ' else '')
        ref: 'console'
        span
          className: 'before-cursor'
          _.map (@props.output || []), (pair, i) ->
            if numCharsToEmit > 0
              [source, text] = pair
              substring = text.substring 0, numCharsToEmit
              numCharsToEmit -= substring.length
              span { className: source, key: "output#{i}" },
                substring
        if @props.pendingStdin != null
          input
            ref: 'stdin'
            type: 'text'
            className: 'stdin'
            value: @props.pendingStdin
            onChange: (e) =>
              @props.doChangeInput e.target.value
            onKeyPress: (e) =>
              if e.keyCode == 13
                @props.doSubmitInput "#{e.target.value}\n"
        else
          div
            className: 'cursor'

module.exports = ConsoleComponent
