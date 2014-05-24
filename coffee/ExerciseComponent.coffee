type        = React.PropTypes
RELOAD_ICON = "\u27f3"
RIGHT_ARROW = "\u279c"
DOWN_ARROW  = "\u2193"
EM_DASH     = "\u2014"
NOT_EQUALS  = "\u2260"
SOUTH_EAST  = "\u2198"

ExerciseComponent = React.createClass

  displayName: 'ExerciseComponent'

  propTypes:
    color: type.string.isRequired
    code: type.string.isRequired
    expectedOutput: type.string
    actualOutput: type.array
    doCommand: type.object.isRequired

  getInitialState: ->
    predictedOutput: null

  render: ->
    { br, button, div, h1, img, input, label, p, small, span, textarea } = React.DOM

    actualOutput = _.map(@props.actualOutput, (pair) -> pair[1]).join('')
    expectedOutput = @props.expectedOutput || @state.predictedOutput

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
          div
            className: 'banner blue'
            "Predict the output#{SOUTH_EAST}"
        when 'red'
          div { className: 'banner red' }, 'Troubleshooting'
        when 'green'
          div { className: 'banner green' }, 'Implementation'
        when 'orange'
          div { className: 'banner green' }, 'Simplification'

      div { className: 'col-1-of-2' },
        label { className: 'code' },
          switch @props.color
            when 'yellow' then 'Example Code'
            when 'blue'   then 'Code to look over'
            when 'red'    then 'Code to fix'
            when 'green'  then 'Write code to match expected output'
            when 'orange' then 'Code to simplify'
        textarea
          className: 'code'
          defaultValue: @props.code

      div { className: 'col-2-of-2' },
        if @props.color == 'blue'
          div {},
            label {}, "What will the output be?"
            textarea
              className: 'expected'
              placeholder: 'Enter prediction here and click Run to check your answer.'
              value: @state.predictedOutput
              onChange: (e) => @setState predictedOutput: e.target.value
        else if @props.expectedOutput != null
          div {},
            label {}, 'Expected output'
            div { className: 'expected' },
              @props.expectedOutput
        else
          div { style: { height: '175px' } }

        label {},
          'Actual output'
          if expectedOutput != null && @props.actualOutput != null
            if actualOutput == expectedOutput
              span { className: 'equals' }, ' = Expected'
            else
              span { className: 'not-equals' }, " #{NOT_EQUALS} Expected"
        if @props.actualOutput == null
          if @props.color == 'blue'
            div { className: 'actual hidden' }
          else
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
            _.map @props.actualOutput, (pair, i) ->
              [color, line] = pair
              span { className: color, key: "line#{i}" }, line

        div { className: 'buttons-under' },
          button
            className: 'debug'
            disabled: true
            'Debug'
          button
            className: 'run'
            onClick: =>
              if @props.color == 'blue' && expectedOutput == null
                window.alert 'Please type in a prediction before clicking Run'
              else
                @props.doCommand.run()
            'Run'

module.exports = ExerciseComponent
