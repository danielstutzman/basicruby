type           = React.PropTypes

RIGHT_ARROW    = '\u2192'

MILLIS_FOR_HIGHLIGHT                   = 300
MILLIS_FOR_SCROLLED_INSTRUCTIONS       = 500
MILLIS_FOR_SCROLLED_INSTRUCTIONS_TENTH = 5

InstructionsComponent = React.createClass

  displayName: 'InstructionsComponent'

  propTypes:
    code:             type.string
    currentLine:      type.number
    currentCol:       type.number
    highlightedRange: type.array

  shouldComponentUpdate: (nextProps, nextState) ->
    if nextProps.code == @props.code &&
       nextProps.currentLine == @props.currentLine &&
       nextProps.highlightedRange == @props.highlightedRange &&
       nextProps.highlightedLineNum == @props.highlightedLineNum
      nextProps.animationFinished()
      false
    else
      true

  componentDidUpdate: (prevProps, prevState) ->
    millis = 0

    if @props.highlightedRange != prevProps.highlightedRange ||
       @props.highlightedLineNum != prevProps.highlightedLineNum
      millis = MILLIS_FOR_HIGHLIGHT
    else if @props.currentLine != prevProps.currentLine && @props.currentLine
      millis = @_scrollInstructions()

    window.setTimeout @props.animationFinished, millis

  _scrollInstructions: ->
    $pointer = @refs.pointer.getDOMNode()
    $content = @refs.content.getDOMNode()
    $pointer.style.display = 'block'
    $content.style.display = 'block'
    $element_1 = @refs["num1"].getDOMNode()
    $element_n = @refs["num#{@props.currentLine}"].getDOMNode()
    old_scroll_top = $content.scrollTop
    new_scroll_top = $element_n.getBoundingClientRect().top -
                     $element_1.getBoundingClientRect().top
    animateScrollTop = (progress) ->
      progress = 1.0 if progress > 1.0
      $content.scrollTop = (1.0 - progress) * old_scroll_top +
        progress * new_scroll_top
      if progress < 1.0
        window.setTimeout (=> animateScrollTop (progress + 0.1)),
          MILLIS_FOR_SCROLLED_INSTRUCTIONS_TENTH
    animateScrollTop 1.0
    MILLIS_FOR_SCROLLED_INSTRUCTIONS

  render: ->
    { br, div, label, span } = React.DOM

    if @props.highlightedRange
      [startLine, startCol, endLine, endCol] = @props.highlightedRange
    highlightedLineNum = @props.highlightedLineNum

    div {},
      label {}, 'Instructions'
      div
        className: 'instructions'
        if @props.currentLine
          div
            className: 'pointer'
            ref: 'pointer'
            RIGHT_ARROW
        if @props.currentLine
          div
            className: 'content'
            ref: 'content'
            br { key: 1 } # blank line at beginning
            _.map @props.code.split("\n"), (line, i) ->
              num = i + 1
              div { key: num },
                div
                  ref: "num#{num}"
                  className: "num _#{num}"
                  num
                div
                  className: "code _#{num}"
                  if line == ''
                    br {}
                  else if num == startLine && num == endLine
                    div {},
                      span { key: 'before-highlight' },
                        line.substring 0, startCol
                      span { key: 'highlight', className: 'highlight' },
                        line.substring startCol, endCol
                      span { key: 'after-highlight' },
                        line.substring endCol
                  else if num == highlightedLineNum
                    span { className: 'highlight' },
                      line
                  else
                    line
            br { key: 2, style: { clear: 'both' } }
            br { key: 3 }

module.exports = InstructionsComponent
