type           = React.PropTypes

RIGHT_ARROW    = '\u2192'

MILLIS_FOR_SCROLLED_INSTRUCTIONS       = 500
MILLIS_FOR_SCROLLED_INSTRUCTIONS_TENTH = 5

InstructionsComponent = React.createClass

  displayName: 'InstructionsComponent'

  propTypes:
    pos:           type.string
    instructions:  type.string.isRequired
    highlightLine: type.bool.isRequired

  _instructionsToHtml: ->

  componentDidUpdate: (prevProps, prevState) ->
    if @props.pos != prevProps.pos && @props.pos
      @_scrollInstructions (->)

  _scrollInstructions: (callback) ->
    $pointer = @refs.pointer.getDOMNode()
    $content = @refs.content.getDOMNode()
    line_num = @props.pos.split(',')[0]
    $pointer.style.display = 'block'
    $content.style.display = 'block'
    $element_1 = @refs["num1"].getDOMNode()
    $element_n = @refs["num#{line_num}"].getDOMNode()
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
      else
        window.setTimeout callback, MILLIS_FOR_SCROLLED_INSTRUCTIONS
    animateScrollTop 0.1

  render: ->
    { br, div } = React.DOM

    maybe_bold = (line_num) =>
      if @props.highlightLine && @props.pos &&
        parseInt(@props.pos.split(',')[0]) == line_num then 'bold ' else ''

    div
      className: 'instructions'
      if @props.pos
        div
          className: 'pointer'
          ref: 'pointer'
          RIGHT_ARROW
      if @props.pos
        div
          className: 'content'
          ref: 'content'
          br { key: 1 } # blank line at beginning
          _.map @props.instructions.split("\n"), (line, i) ->
            num = i + 1
            div
              key: num
              div
                ref: "num#{num}"
                className: "num _#{num}"
                num
              div
                className: "code _#{num} #{maybe_bold(num)}"
                line
          br { key: 2, style: { clear: 'both' } }
          br { key: 3 }

module.exports = InstructionsComponent
