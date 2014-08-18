type           = React.PropTypes
ENTER_KEY      = 13
UP_ARROW       = "\u2191"

ConsoleComponent = React.createClass

  displayName: 'ConsoleComponent'

  propTypes:
    output: type.array
    numCharsToOutput: type.number.isRequired
    pendingStdin: type.string
    doChangeInput: type.func.isRequired
    doSubmitInput: type.func.isRequired

  shouldComponentUpdate: (nextProps, nextState) ->
    nextProps.output?.length != @props.output?.length ||
    nextProps.pendingStdin != @props.pendingStdin ||
    nextProps.numCharsToOutput != @props.numCharsToOutput

  componentDidUpdate: (prevProps, prevState) ->
    if @props.pendingStdin != prevProps.pendingStdin &&
       @props.pendingStdin != null
      @refs.console.getDOMNode().scrollTop = @refs.console.getDOMNode().scrollHeight
      @refs.stdin.getDOMNode().focus()
    else if @props.numCharsToOutput != prevProps.numCharsToOutput
      @refs.console.getDOMNode().scrollTop = @refs.console.getDOMNode().scrollHeight

  render: ->
    { div, input, label, span } = React.DOM

    numCharsToEmit = @props.numCharsToOutput

    div { className: 'console-with-label' },
      div { className: 'table-row for-label' },
        label {}, 'Output'
      div { className: 'table-row' },
        div { className: 'table-cell' },
          div
            className: 'console'
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
            if @props.pendingStdin != null
              div
                className: 'stdin-reminder'
                "#{UP_ARROW} Type something on the keyboard, then press Enter."
            else
              div
                className: 'cursor'

module.exports = ConsoleComponent
