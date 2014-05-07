type           = React.PropTypes

VariablesComponent = React.createClass

  displayName: 'VariablesComponent'

  propTypes:
    vars: type.object.isRequired

  render: ->
    { br, div, table, td, th, tr } = React.DOM

    div
      className: 'variables'
      table
        border: true
        tr { key: 'var_names' },
          _.map @props.vars.keys, (var_name) =>
            th
              key: var_name.$to_s()
              var_name.$to_s()
        tr { key: 'var_values' },
          _.map @props.vars.keys, (var_name) =>
            var_value = @props.vars.map[var_name]
            td
              key: var_name.$to_s()
              var_value.$inspect()

module.exports = VariablesComponent
