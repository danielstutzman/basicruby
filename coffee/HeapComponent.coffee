ValueComponent = require './ValueComponent.coffee'

type           = React.PropTypes

HeapComponent = React.createClass

  displayName: 'HeapComponent'

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

    heap = {}
    addToHeap = (value) ->
      type = value.$class && value.$class().$to_s()
      if type != 'Numeric' && type != 'Boolean'
        object_id = value.$object_id()
        unless heap.hasOwnProperty(object_id)
          heap[object_id] = value
          if value.$class && value.$class().$to_s() == 'Array'
            for element in value
              addToHeap element
    for var_name in var_names
      var_value = @props.vars.map[var_name]
      if var_value
        addToHeap var_value

    if @props.startedVarNames
      future_var_names = _.difference @props.startedVarNames, var_names
    else
      future_var_names = []

    numerically = (x, y) -> x - y # comparator function

    div { className: 'vars-and-heap' },
      div { className: 'black-background' }, ''
      div { className: 'scroller' },
        div { className: 'gray-background' }, ''
        div { className: 'just-vars' },
          table {},
            tr { key: 'header1' },
              th { className: 'bigger', colSpan: '2' }, 'Vars'
            tr { key: 'header2' },
              th { className: 'leftmost' }, 'Name'
              th { }, 'ID'
            _.map var_names, (var_name) =>
              var_value = @props.vars.map[var_name]
              tr { key: var_name },
                td { className: 'left' }, var_name
                td { },
                  ValueComponent
                    value: var_value
                    object_ids: _.keys(heap)
                    show_type: false
        div { className: 'between' }, ''
        div { className: 'just-heap' },
          table {},
            tr { key: 'header1' },
              th { className: 'bigger', colSpan: '3' }, 'Heap'
            tr { key: 'header2' },
              th { className: 'left' }, 'ID'
              th { }, 'Type'
              th { }, 'Object'
            _.map _.keys(heap).sort(numerically), (object_id) ->
              value = heap[object_id]
              tr { key: object_id },
                td { className: 'left' },
                  div { className: 'object-id' },
                    object_id
                td { },
                  div { className: 'value' },
                    div { className: 'type' },
                      value.$class().$to_s()
                td { },
                  ValueComponent
                    value: value
                    object_ids: _.without _.keys(heap), object_id
                    show_type: false

module.exports = HeapComponent
