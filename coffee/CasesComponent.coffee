type           = React.PropTypes
RIGHT_ARROW    = '\u2192'
RIGHT_TRIANGLE = '\u25b6'
NBSP           = "\u00a0"

CasesComponent = React.createClass

  displayName: 'CasesComponent'

  propTypes:
    cases:        type.object.isRequired
    runTestCases: type.func.isRequired

  render: ->
    { br, button, div, span, table, td, th, tr } = React.DOM

    multiLineString = (string) ->
      if string
        lines = string.split("\n")
        _.map lines, (line, i) ->
          div { key: "line#{i}", className: 'line' },
            if line == ''
              div { className: 'empty-line' }
            else
              line
            if i < lines.length - 1
              br {}

    div {},
      div { className: 'buttons' },
        button
          onClick: @props.runTestCases
          className:
            (if @props.cases.currentCaseNum != null then 'active ' else '')
          "#{RIGHT_TRIANGLE}#{RIGHT_TRIANGLE} Run test cases"
      table {},
        tr {},
          th {}, 'Input'
          th {}, 'Expected', br {}, 'Output'
          th {}, 'Actual', br {}, 'Output'
        _.map @props.cases.cases, (_case, case_num) =>
          tr
            key: "case#{case_num}"
            className:
              if @props.cases.currentCaseNum == case_num
                'highlighted'
            td { className: 'input' },
              div { className: 'string' },
                multiLineString _case.input
            td { className: 'expected-output' },
              div { className: 'string' },
                multiLineString _case.expectedOutput
            td { className: 'actual-output' },
              if _case.actualOutput == null
                if @props.cases.currentCaseNum != null
                  div { className: 'dot-dot-dot' }, '...'
              else
                div { className: 'string' },
                  multiLineString _case.actualOutput

module.exports = CasesComponent
