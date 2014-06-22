type        = React.PropTypes
NOT_EQUALS  = "\u2260"
DOWN_ARROW  = "\u2193"

CasesComponent = React.createClass

  displayName: 'CasesComponent'

  propTypes:
    color:     type.string.isRequired
    cases:     type.array.isRequired
    doCommand: type.object.isRequired

  componentDidMount: ->
    if @props.color == 'blue'
      window.setTimeout (=> @refs.prediction0.getDOMNode().focus()), 100

  render: ->
    { br, button, div, input, span, table, td, th, tr, textarea } = React.DOM

    hasCode            = _.some @props.cases, (case_) -> case_.code
    hasInputs          = _.some @props.cases, (case_) -> case_.input
    hasExpectedOutputs = _.some @props.cases, (case_) -> case_.expected_output
    hasUnpredictedOutputs = _.some @props.cases, (case_) ->
                               case_.predicted_output == undefined

    div { className: 'col-2-of-2' },
      div { className: 'expected' },
        if hasCode
          table {},
            tr {},
              th {}, 'Test code'
            tr {},
              td {},
                textarea
                  className: 'expected'
                  readOnly: true
                  value: _.map(@props.cases, (_case) => _case.code).join('')

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
              if hasCode
                'Test results'
              else
                'Actual output'

              if hasExpectedOutputs && @props.cases.length == 1
                case0 = @props.cases[0]
                if @props.color == 'blue'
                  if case0.actual_output == undefined
                    ''
                  else if case0.passed
                    span { className: 'passed' }, '=Predicted'
                  else
                    span { className: 'failed' }, "#{NOT_EQUALS}Predicted"
                else
                  if case0.actual_output == undefined
                    ''
                  else if case0.passed
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
                    if /^test([a-zA-Z0-9_]+) PASSED\n/.exec(line)
                      span { className: 'passed', key: "line#{i}" }, line
                    else
                      span { className: color, key: "line#{i}" }, line
              if hasExpectedOutputs && @props.cases.length > 1
                if @props.color == 'blue'
                  if _case.actual_output == undefined
                    null
                  else if _case.passed
                    td {},
                      span { className: 'passed' }, '='
                  else
                    td {},
                      span { className: 'failed' }, NOT_EQUALS
                else
                  if _case.passed
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

module.exports = CasesComponent
