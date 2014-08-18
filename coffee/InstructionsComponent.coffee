type           = React.PropTypes

RIGHT_ARROW    = '\u2192'

InstructionsComponent = React.createClass

  displayName: 'InstructionsComponent'

  propTypes:
    code:             type.string
    currentLine:      type.number
    currentCol:       type.number
    highlightedRange: type.array
    currentScrollTop: type.number.isRequired

  shouldComponentUpdate: (nextProps, nextState) ->
    nextProps.code != @props.code ||
    nextProps.currentLine != @props.currentLine ||
    nextProps.highlightedRange != @props.highlightedRange ||
    nextProps.currentScrollTop != @props.currentScrollTop

  componentDidUpdate: (prevProps, prevState) ->
    return unless @refs.pointer && @refs.content && @props.currentScrollTop > 0
    $pointer = @refs.pointer.getDOMNode()
    $content = @refs.content.getDOMNode()
    $pointer.style.display = 'block'
    $content.style.display = 'block'
    $element_1 = @refs['blank1'].getDOMNode()
    middleOfLine = @props.currentScrollTop + 0.5
    $element_m = @refs["num#{Math.floor(middleOfLine)}"].getDOMNode()
    $element_n = @refs["num#{Math.ceil(middleOfLine)}"].getDOMNode()
    progress = middleOfLine - Math.floor(middleOfLine)
    y = $element_n.getBoundingClientRect().top * progress +
        $element_m.getBoundingClientRect().top * (1 - progress)
    arrowCenterY = $pointer.getBoundingClientRect().top -
      @refs.instructions.getDOMNode().getBoundingClientRect().top
    $content.scrollTop = y - $element_1.getBoundingClientRect().top - arrowCenterY

  render: ->
    { br, div, label, span } = React.DOM

    if @props.highlightedRange
      [startLine, startCol, endLine, endCol] = @props.highlightedRange

    div { className: 'instructions-with-label' },
      div { className: 'table-row for-label' },
        label {}, 'Instructions'
      div { className: 'table-row' },
        div
          className: 'instructions'
          ref: 'instructions'
          if @props.currentLine
            div
              className: 'pointer'
              ref: 'pointer'
              RIGHT_ARROW
          div
            className: 'content'
            ref: 'content'

            # blank space at the beginning so we have freedom when scrolling
            div { className: 'blank', ref: 'blank1' }

            # concat the ending newline so pointer knows the bottom-y
            # of the last line's div, so it can center vertically
            _.map @props.code.split("\n").concat(''), (line, i) ->
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
                  else if num == startLine && num < endLine
                    div {},
                      span { key: 'before-highlight' },
                        line.substring 0, startCol
                      span { key: 'highlight', className: 'highlight' },
                        line.substring startCol
                  else if num > startLine && num == endLine
                    div {},
                      span { key: 'highlight', className: 'highlight' },
                        line.substring 0, endCol
                      span { key: 'after-highlight' },
                        line.substring endCol
                  else if num > startLine && num < endLine
                    div {},
                      span { key: 'highlight', className: 'highlight' },
                        line
                  else
                    line

            br { key: 4, style: { clear: 'both' } }

            # blank space at the ending so we have freedom when scrolling
            div { className: 'blank', ref: 'blank2' }

module.exports = InstructionsComponent
