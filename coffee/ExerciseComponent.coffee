type        = React.PropTypes
RELOAD_ICON = "\u27f3"
RIGHT_ARROW = "\u279c"
DOWN_ARROW  = "\u2193"
EM_DASH     = "\u2014"
NOT_EQUALS  = "\u2260"
SOUTH_EAST  = "\u2198"
X_FOR_CLOSE = "\u00d7"
HEIGHT_OF_VIDEO_CONTROLS = 35

ExerciseComponent = React.createClass

  displayName: 'ExerciseComponent'

  propTypes:
    color: type.string.isRequired
    code: type.string.isRequired
    cases: type.array.isRequired
    pathForVideo: type.string
    pathForVideoPath: type.string
    showingSuccessPopup: type.bool.isRequired
    showingYellowVideo: type.bool.isRequired
    doCommand: type.object.isRequired

  componentDidMount: ->
    if @props.color == 'blue'
      window.setTimeout (=> @refs.prediction0.getDOMNode().focus()), 100

  render: ->
    { a, br, button, div, h1, img, input, label, p, small, source,
      span, table, td, th, tr, textarea, video } = React.DOM

    hasInputs             = _.some @props.cases, (case_) -> case_.input
    hasExpectedOutputs    = _.some @props.cases, (case_) -> case_.expected_output
    hasUnpredictedOutputs = _.some @props.cases, (case_) ->
                               case_.predicted_output == null

    div { className: @props.color },

      div { className: 'buttons-above' },
        if @props.color == 'yellow' || @props.color == 'blue'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null ||
                      @props.cases[0].actual_output == undefined
            onClick: (e) => @props.doCommand.nextRep e
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
        when 'yellow'
          div { className: 'banner yellow' }, 'Demonstration'
        when 'blue'
          div
            className: 'banner blue'
            "Predict the output#{SOUTH_EAST}"
        when 'red'
          div
            className: 'banner red'
            "Fix the program to output#{SOUTH_EAST}"
        when 'green'
          div
            className: 'banner green'
            "Write a program to output#{SOUTH_EAST}"
        when 'orange'
          div { className: 'banner green' }, 'Simplification'

      div { className: 'col-1-of-2' },
        label { className: 'code' },
          switch @props.color
            when 'yellow' then 'Code to look over'
            when 'blue'   then 'Code to look over'
            when 'red'    then 'Code to edit'
            when 'green'  then 'Write code here'
            when 'orange' then 'Code to simplify'
        textarea
          className: 'code'
          defaultValue: @props.code

      div { className: 'col-2-of-2' },
        div { className: 'expected' },
          if @props.color == 'yellow' && @props.pathForVideo
            div { className: 'little-video-container' },
              img
                src: @props.pathForVideoPoster
                width: 250
                height: 140
              a
                href: '#'
                onClick: (e) =>
                  @props.doCommand.showYellowVideo e.target
                  e.preventDefault()
                div { className: 'little-video-play-button' }

          else if hasExpectedOutputs
            table {},
              tr { key: 'header' },
                if hasInputs
                  th {}, 'Input'
                if @props.color == 'blue'
                  if @props.cases.length == 1
                    th {}, 'What will the output be?'
                  else
                    th {}, 'Predicted output'
                else
                  th {}, 'Expected output'
              _.map @props.cases, (_case, case_num) =>
                tr { key: "case#{case_num}" },
                  if hasInputs
                    td {},
                      span { className: 'stdin' }, _case.input
                  td {},
                    if @props.color == 'blue'
                      textarea
                        ref: "prediction#{case_num}"
                        className: "expected length#{@props.cases.length}"
                        placeholder: if hasInputs
                            'Predicted output for this input'
                          else
                            'Enter prediction here and click Run to check your answer'
                        value: _case.predicted_output
                        onChange: (e) =>
                          newText = e.target.value
                          @props.doCommand.setPredictedOutput case_num, newText
                    else
                      _case.expected_output

        div { className: 'actual' },
          table {},
            tr { key: 'header' },
              if hasInputs
                th {}, 'Input'
              th {},
                'Actual output'
                if hasExpectedOutputs && @props.cases.length == 1
                  case0 = @props.cases[0]
                  if @props.color == 'blue'
                    if case0.actual_output == undefined
                      ''
                    else if case0.actual_matches_expected
                      span { className: 'passed' }, ' = Predicted'
                    else
                      span { className: 'failed' }, " #{NOT_EQUALS} Predicted"
                  else
                    if case0.actual_matches_expected
                      span { className: 'passed' }, ' = Expected'
                    else
                      span { className: 'failed' }, " #{NOT_EQUALS} Expected"
              if hasExpectedOutputs && @props.cases.length > 1
                if @props.color == 'blue'
                  if @props.cases[0].actual_output != undefined
                    th {}, ''
                else
                  th {}, ''
            _.map @props.cases, (_case, case_num) =>
              tr { key: "case#{case_num}" },
                if hasInputs
                  td {},
                    span { className: 'stdin' }, _case.input
                if _case.actual_output == undefined
                  td { className: 'hidden' },
                    if @props.cases.length == 1
                      if @props.color == 'yellow'
                        div { className: 'click-run' },
                          'Click Run'
                          br {}
                          'to see'
                          br {}
                          'output'
                          br {}
                          DOWN_ARROW
                      else if @props.color == 'blue'
                        div { className: 'click-run' },
                          'Click Run'
                          br {}
                          'to check'
                          br {}
                          'answer'
                          br {}
                          DOWN_ARROW
                else
                  td {},
                    _.map _case.actual_output, (pair, i) ->
                      [color, line] = pair
                      span { className: color, key: "line#{i}" }, line
                if hasExpectedOutputs && @props.cases.length > 1
                  if @props.color == 'blue'
                    if _case.actual_output == undefined
                      null
                    else if _case.actual_matches_expected
                      td {},
                        span { className: 'passed' }, '='
                    else
                      td {},
                        span { className: 'failed' }, NOT_EQUALS
                  else
                    if _case.actual_matches_expected
                      td {},
                        span { className: 'passed' }, '='
                    else
                      td {},
                        span { className: 'failed' }, NOT_EQUALS

        div { className: 'buttons-under' },
          button
            className: 'debug'
            onClick: => @props.doCommand.debug()
            'Debug'
          button
            className: 'run'
            onClick: =>
              if @props.color == 'blue' && hasUnpredictedOutputs
                if @props.cases.length == 1
                  window.alert 'Please type in a prediction before clicking Run.'
                else
                  window.alert "You haven't predicted output for all the inputs yet."
              else
                @props.doCommand.run()
            if @props.cases == null || @props.cases.length == 1
              'Run'
            else
              'Run Tests'

      if @props.showingSuccessPopup
        div
          ref: 'success'
          className: 'success'
          a
            className: 'close-button'
            href: '#'
            onClick: (e) =>
              @props.doCommand.closeSuccessPopup()
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
            onClick: (e) =>
              console.log 'do another'
              @props.doCommand.nextRep e
            "#{RELOAD_ICON} Do another"
          br {}
          button
            className: 'go-on'
            disabled: @props.doCommand.next == null
            onClick: (e) => @props.doCommand.next e
            "#{RIGHT_ARROW} Go on"

      if @props.showingYellowVideo
        div { className: 'big-video-background' },
          a
            className: 'close-button'
            href: '#'
            onClick: (e) =>
              @props.doCommand.closeYellowVideo()
              e.preventDefault()
            X_FOR_CLOSE
          video
            width: 750
            height: 420
            poster: @props.pathForVideoPoster
            autoPlay: 'autoPlay'
            onClick: (e) ->
              video = e.target
              mouseY = e.clientY - video.getBoundingClientRect().top
              if mouseY < video.height - HEIGHT_OF_VIDEO_CONTROLS
                if video.paused
                  video.play()
                else
                  video.pause()
                e.preventDefault()
            onMouseEnter: (e) -> e.target.setAttribute 'controls', 'controls'
            onMouseLeave: (e) -> e.target.removeAttribute 'controls'
            source
              src: @props.pathForVideo
              type: 'video/mp4'

module.exports = ExerciseComponent
