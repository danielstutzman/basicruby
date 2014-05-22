type        = React.PropTypes
RELOAD_ICON = "\u27f3"
RIGHT_ARROW = "\u279c"


ExerciseComponent = React.createClass

  displayName: 'ExerciseComponent'

  propTypes:
    title: type.string.isRequired
    color: type.string.isRequired
    code: type.string.isRequired
    expectedOutput: type.string
    actualOutput: type.string

  render: ->
    { button, div, h1, img, input, label, textarea } = React.DOM

    div {},
      div { className: 'title' }, @props.title
      div { className: 'buttons' },
        button {}, "#{RELOAD_ICON} Do another"
        button {}, "#{RIGHT_ARROW} Go on"
        img
          src: 'app/assets/images/exercise_icons/light_bulb30.png'
          width: 60
          height: 60
          style: { float: 'left' }
        h1 {}, 'Demonstration'
        div { className: 'col-1-of-2' },
          label {}, 'Code'
          textarea
            className: 'code'
            value: @props.code
        div { className: 'col-2-of-2' },
          label {}, 'Expected output'
          div { className: 'expected' },
            @props.expectedOutput

          label {}, 'Actual output'
          div { className: 'actual' },
            @props.expectedOutput

          div { className: 'under' },
            button {}, 'Debug'
            button {}, 'Run'

module.exports = ExerciseComponent
