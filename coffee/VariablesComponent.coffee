ValueComponent = require './ValueComponent.coffee'

type           = React.PropTypes

VariablesComponent = React.createClass

  displayName: 'VariablesComponent'

  propTypes:
    vars: type.object.isRequired
    started_var_names: type.array.isRequired

  render: ->
    { br, div, table, td, th, tr } = React.DOM

    if @props.vars.keys
      var_names = _.map @props.vars.keys, (var_name) ->
        var_name.$to_s()
    else
      var_names = []

    future_var_names = _.difference @props.started_var_names, var_names

    div { className: 'variables' },
      table {},
        tr { key: 'var_names' },
          _.map var_names, (var_name) ->
            th { key: var_name },
              var_name
          _.map future_var_names, (var_name) ->
            th { key: var_name, className: 'future' },
              var_name
        tr { key: 'var_values' },
          _.map var_names, (var_name) =>
            var_value = @props.vars.map[var_name]
            td { key: var_name },
              ValueComponent value: var_value
          _.map future_var_names, (var_name) ->
            td { key: var_name, className: 'future' },
              '...'
        tr { key: 'var_pending' },
          _.map var_names, (var_name) =>
            td { key: var_name, className: 'future' },
              if var_name in @props.started_var_names
                '...'

module.exports = VariablesComponent
