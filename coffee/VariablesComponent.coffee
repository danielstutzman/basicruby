ValueComponent = require './ValueComponent.coffee'

type           = React.PropTypes

VariablesComponent = React.createClass

  displayName: 'VariablesComponent'

  propTypes:
    varsStack:      type.array
    showHeapToggle: type.bool.isRequired
    doToggleHeap:   type.func.isRequired

  render: ->
    { br, button, div, label, span, table, td, th, tr } = React.DOM

    div { className: 'variables-with-label' },
      label {},
        if @props.showHeapToggle
          button
            className: 'heap-toggle'
            onClick: (e) => @props.doToggleHeap()
            'Show IDs'
        'Variables'
      div { className: 'variables-scroller' },
        table { className: 'variables' },
          _.map @props.varsStack, (vars, method_num) =>
            if vars and vars.keys
              var_names = _.map vars.keys, ((var_name) -> var_name.$to_s())
            else
              var_names = []
            trs = []
            unless method_num == 0
              trs.push tr { key: "method#{method_num}", className: 'method' },
                td { colSpan: 2 },
                  _.map vars.map['__method_name'][1].$to_s().split("'"), \
                      (part, i) ->
                    className = if i == 1 then 'code' else ''
                    span { key: "part#{i}", className }, part
            trs = trs.concat _.map var_names, (var_name, var_num) =>
              unless var_name.indexOf('__') == 0
                [isPending, var_value] = vars.map[var_name]
                tr { key: "#{method_num}_#{var_name}" },
                  td { className: 'name' }, var_name
                  td { className: 'value' },
                    if var_value != undefined
                      ValueComponent
                        value: var_value
                        object_ids: []
                        show_type: true
                    '...' if isPending
            trs

module.exports = VariablesComponent
