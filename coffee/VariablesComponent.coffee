ValueComponent = require './ValueComponent.coffee'

type           = React.PropTypes

VariablesComponent = React.createClass

  displayName: 'VariablesComponent'

  propTypes:
    vars:            type.object
    startedVarNames: type.array

  render: ->
    { br, div, label, table, td, th, tr } = React.DOM

    if @props.vars and @props.vars.keys
      var_names = _.map @props.vars.keys, (var_name) ->
        var_name.$to_s()
    else
      var_names = []

    if @props.startedVarNames
      future_var_names = _.difference @props.startedVarNames, var_names
    else
      future_var_names = []

    div { className: 'variables-with-label' },
      label {}, 'Variables'
      div { className: 'variables-scroller' },
        table { className: 'variables' },
          _.map var_names, (var_name) =>
            var_value = @props.vars.map[var_name]
            tr { key: var_name },
              td {}, var_name
              td {},
                ValueComponent(value: var_value) if var_value != undefined
                '...' if @props.startedVarNames.indexOf(var_name) != -1
          _.map future_var_names, (var_name) =>
            tr { key: var_name },
              td {}, var_name
              td { className: 'future' },
              '...'

module.exports = VariablesComponent
