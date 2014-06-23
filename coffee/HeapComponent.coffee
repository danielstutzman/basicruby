ValueComponent = require './ValueComponent.coffee'

type           = React.PropTypes

HeapComponent = React.createClass

  displayName: 'HeapComponent'

  propTypes:
    varsStack:    type.array
    doToggleHeap: type.func.isRequired

  render: ->
    { br, button, div, span, table, tbody, td, th, tr } = React.DOM

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
    for vars in @props.varsStack
      if vars and vars.keys
        for var_name in vars.keys
          if var_name.indexOf('__') != 0
            var_value = vars.map[var_name][1]
            addToHeap var_value if var_value

    numerically = (x, y) -> x - y # comparator function

    div { className: 'vars-and-heap' },
      div { className: 'black-background' }, ''
      div { className: 'scroller' },
        div { className: 'gray-background' }, ''
        div { className: 'just-vars' },
          table {},
            tbody {}, # bugfix: cannot read property parentNode of undefined
              tr { key: 'header1' },
                th { className: 'bigger', colSpan: '2' }, 'Vars'
              tr { key: 'header2' },
                th { className: 'leftmost' }, 'Name'
                th { }, 'ID'
              _.map @props.varsStack, (vars, method_num) =>
                trs = []
                if vars and vars.keys
                  var_names = _.map vars.keys, ((var_name) -> var_name.$to_s())
                else
                  var_names = []
                unless method_num == 0
                  trs.push tr { key: "method#{method_num}", className: 'method' },
                    td { colSpan: 2 },
                      _.map vars.map['__method_name'][1].$to_s().split("'"), \
                          (part, i) ->
                        className = if i == 1 then 'code' else ''
                        span { key: "part#{i}", className }, part
                for var_name in var_names
                  if var_name.indexOf('__') != 0
                    var_value = vars.map[var_name][1]
                    trs.push tr { key: var_name },
                      td { className: 'left' }, var_name
                      td { },
                        if var_value
                          ValueComponent
                            value: var_value
                            object_ids: _.keys(heap)
                            show_type: false
                trs
        div { className: 'between' }, ''
        div { className: 'just-heap' },
          table {},
            tbody {}, # bugfix: cannot read property parentNode of undefined
              tr { key: 'header1' },
                th { className: 'bigger', colSpan: '3' }, 'Heap'
              tr { key: 'header2' },
                th { className: 'left' }, 'ID'
                th { }, 'Type'
                th { }, 'Object'
              _.map _.keys(heap).sort(numerically), (object_id, i) ->
                value = heap[object_id]
                tr { key: "object_id#{object_id}" },
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
        button
          className: 'heap-toggle'
          onClick: (e) => @props.doToggleHeap()
          'Hide IDs'


module.exports = HeapComponent
