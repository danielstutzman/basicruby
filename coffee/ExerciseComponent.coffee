type        = React.PropTypes
RELOAD_ICON = "\u27f3"
RIGHT_ARROW = "\u279c"
DOWN_ARROW  = "\u2193"
EM_DASH     = "\u2014"

ExerciseComponent = React.createClass

  displayName: 'ExerciseComponent'

  propTypes:
    color: type.string.isRequired
    code: type.string.isRequired
    expectedOutput: type.string
    actualOutput: type.string
    doCommand: type.object.isRequired

  render: ->
    { br, button, div, h1, img, input, label, textarea } = React.DOM

    div { className: @props.color },

      div { className: 'buttons-above' },
        button { className: 'do-another' },
          if @props.color == 'yellow'
            "#{RELOAD_ICON} See another"
          else
            "#{RELOAD_ICON} Do another"
        button
          className: 'next'
          disabled: (@props.doCommand.next == undefined)
          onClick: (e) => @props.doCommand.next e
          "#{RIGHT_ARROW} Go on"

      switch @props.color
        when 'yellow'
          div { className: 'banner yellow' }, 'Demonstration'
        when 'blue'
          div { className: 'banner blue' }, 'Prediction'
        when 'red'
          div { className: 'banner red' }, 'Troubleshooting'
        when 'green'
          div { className: 'banner green' }, 'Implementation'
        when 'orange'
          div { className: 'banner green' }, 'Simplification'

      div { className: 'col-1-of-2' },
        label {}, 'Code'
        textarea
          className: 'code'
          defaultValue: @props.code

      div { className: 'col-2-of-2' },
        if @props.expectedOutput != null
          div {},
            label {}, 'Expected output'
            div { className: 'expected' },
              @props.expectedOutput
        else
          div { style: { height: '175px' } }

        label {}, 'Actual output'
        if @props.actualOutput == null
          div { className: 'actual hidden' },
            'Click Run'
            br {}
            'to see'
            br {}
            'output'
            br {}
            DOWN_ARROW
        else
          div { className: 'actual shown' },
            @props.actualOutput

        div { className: 'buttons-under' },
          button
            className: 'debug'
            disabled: true
            'Debug'
          button
            className: 'run'
            onClick: => @props.doCommand.run()
            'Run'

module.exports = ExerciseComponent
