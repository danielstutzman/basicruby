CasesComponent = require './CasesComponent.coffee'

type        = React.PropTypes
RELOAD_ICON = "\u27f3"
RIGHT_ARROW = "\u279c"
EM_DASH     = "\u2014"
SOUTH_EAST  = "\u2198"
X_FOR_CLOSE = "\u00d7"

ExerciseComponent = React.createClass

  displayName: 'ExerciseComponent'

  propTypes:
    color:     type.string.isRequired
    code:      type.string.isRequired
    cases:     type.array.isRequired
    popup:     type.string
    doCommand: type.object.isRequired

  render: ->
    { a, br, button, div, h1, input, label, p, span, textarea } = React.DOM

    div { className: @props.color },

      div { className: 'buttons-above' },
        if @props.color == 'yellow' || @props.color == 'blue'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null ||
                      @props.cases[0].actual_output == undefined
            onClick: (e) => @props.doCommand.nextRep e, true
            "#{RELOAD_ICON} See another"

        if @props.color == 'yellow' || @props.color == 'blue'
          button
            className: 'next'
            disabled: @props.doCommand.next== null ||
                      @props.cases[0].actual_output == undefined
            onClick: (e) => @props.doCommand.next e
            "#{RIGHT_ARROW} Go on"

        if @props.color == 'red' || @props.color == 'green'
          button
            className: 'show-solution'
            onClick: => @props.doCommand.showSolution()
            'Show solution'

      switch @props.color
        when 'purple'
          div { className: 'banner purple' }, 'Watch the introduction'
        when 'yellow'
          div { className: 'banner yellow' }, 'Run this example'
        when 'blue'
          div
            className: 'banner blue'
            "Predict the output#{SOUTH_EAST}"
        when 'red'
          div
            className: 'banner red'
            if @props.cases[0].code
              "Fix the program to pass #{SOUTH_EAST}"
            else
              "Fix the program to output#{SOUTH_EAST}"
        when 'green'
          div
            className: 'banner green'
            if @props.cases[0].code
              "Write a program to pass #{SOUTH_EAST}"
            else
              "Write a program to output#{SOUTH_EAST}"
        when 'orange'
          div { className: 'banner green' }, 'Simplification'

      div { className: 'col-1-of-2' },
        label { className: 'code' },
          switch @props.color
            when 'purple' then 'Code to look over'
            when 'yellow' then 'Code to look over'
            when 'blue'   then 'Code to look over'
            when 'red'    then 'Code to edit'
            when 'green'  then 'Write code here'
            when 'orange' then 'Code to simplify'
        textarea
          className: 'code'
          defaultValue: @props.code

      CasesComponent @props

      if @props.popup == 'PASSED'
        div
          className: 'popup passed'
          a
            className: 'close-button'
            href: '#'
            onClick: (e) =>
              @props.doCommand.closePopup()
              e.preventDefault()
            X_FOR_CLOSE
          h1 {}, 'Congratulations!'
          p {},
            if @props.color == 'blue'
              'You predicted the output correctly!'
            else if @props.color == 'red'
              'You fixed the bug so all the tests pass!'
            else if @props.color == 'green'
              'You got all the tests passing!'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null
            onClick: (e) => @props.doCommand.nextRep e, true
            "#{RELOAD_ICON} Do another"
          br {}
          button
            className: 'go-on'
            disabled: @props.doCommand.next == null
            onClick: (e) => @props.doCommand.next e
            "#{RIGHT_ARROW} Go on"

      if @props.popup == 'FAILED'
        div
          className: 'popup failed'
          a
            className: 'close-button'
            href: '#'
            onClick: (e) =>
              @props.doCommand.closePopup()
              e.preventDefault()
            X_FOR_CLOSE
          h1 {}, 'Not quite'
          p {}, 'Compare the actual output to see what you missed.'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null
            onClick: (e) => @props.doCommand.nextRep e, false
            "#{RELOAD_ICON} Try another"

module.exports = ExerciseComponent
