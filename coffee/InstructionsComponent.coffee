type           = React.PropTypes

RIGHT_ARROW    = '\u2192'
ARROW_CENTER_Y = 129

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
    $element_m = @refs["num#{Math.floor(@props.currentScrollTop)}"].getDOMNode()
    $element_n = @refs["num#{Math.ceil(@props.currentScrollTop)}"].getDOMNode()
    progress = @props.currentScrollTop - Math.floor(@props.currentScrollTop)
    y = $element_n.getBoundingClientRect().top * progress +
        $element_m.getBoundingClientRect().top * (1 - progress)
    $content.scrollTop = y - $element_1.getBoundingClientRect().top - ARROW_CENTER_Y

  render: ->
    { br, div, label, span } = React.DOM

    if @props.highlightedRange
      [startLine, startCol, endLine, endCol] = @props.highlightedRange

    div { className: 'instructions-with-label' },
      label {}, 'Instructions'
      div
        className: 'instructions'
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
