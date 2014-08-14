NBSP = '\u00a0'

ValueComponent = React.createClass

  displayName: 'ValueComponent'

  render: ->
    { br, div, table, tr, td } = React.DOM

    value = @props.value
    object_ids = @props.object_ids
    show_type = @props.show_type

    if value.is_symbol
      type = 'Symbol'
    else
      type = value.$class().$to_s()

    display =
      switch type
        when 'Symbol' then value.$to_s()
        when 'String' then value.$to_s()
        else value.$inspect()

    css_class =
      if display == 'main'
        'main'
      else
        switch type
          when 'String' then 'string'
          when 'Symbol' then 'symbol'
          else ''

    object_id = value.$object_id().toString()

    div { className: "value #{css_class}" },
      if object_ids && object_ids.indexOf(object_id) != -1
        div { key: 'object-id', className: 'object-id' },
          value.$object_id()
      else if type == 'String'
        lines = display.split("\n")
        _.map lines, (line, i) ->
          maybe_last = if (i == lines.length - 1) then 'last' else ''
          div { key: "line#{i}", className: "line #{maybe_last}" },
            if line == ''
              div { className: 'empty-line' }
            else
              line
            if i < lines.length - 1
              br {}
      else if type == 'Array'
        table { className: 'array' },
          tr {},
            if value.length == 0
              td {}, NBSP
            else
              _.map value, (element, i) ->
                td { key: i },
                  div { key: 'index', className: 'index' },
                    i
                  ValueComponent
                    value: element
                    object_ids: object_ids.concat([object_id])
                    show_type: false
      else
        display

      if show_type
        div { key: 'type', className: 'type' },
          type

module.exports = ValueComponent
