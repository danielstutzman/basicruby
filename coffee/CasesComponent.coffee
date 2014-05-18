type           = React.PropTypes
RIGHT_ARROW    = '\u2192'
RIGHT_TRIANGLE = '\u25b6'
NBSP           = '\u00a0'
CHECK_MARK     = '\u2714'
X_MARK         = '\u2718'

CasesComponent = React.createClass

  displayName: 'CasesComponent'

  propTypes:
    cases:        type.object.isRequired
    runTestCases: type.func.isRequired

  render: ->
    { br, button, div, span, table, td, th, tr } = React.DOM

    doCasesHaveInput = _.every @props.cases.cases, (_case) ->
      _case.input != undefined

    s = if @props.cases.cases.length == 1 then '' else 's'

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
          "#{RIGHT_TRIANGLE}#{RIGHT_TRIANGLE} Run test case#{s}"
      table {},
        tr {},
          if doCasesHaveInput
            th {}, 'Input'
          th {}, 'Expected', br {}, 'Output'
          th {}, 'Actual', br {}, 'Output'
          th {}, 'Match?'
        _.map @props.cases.cases, (_case, case_num) =>
          tr
            key: "case#{case_num}"
            className:
              if @props.cases.currentCaseNum == case_num
                'highlighted'
            if doCasesHaveInput
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
            td { className: 'match' },
              if _case.matches == true
                div { className: 'passed' }, CHECK_MARK
              else if _case.matches == false
                div { className: 'failed' }, X_MARK
              else if _case.matches == null &&
                  @props.cases.currentCaseNum != null
                div { className: 'dot-dot-dot' }, '...'

module.exports = CasesComponent
