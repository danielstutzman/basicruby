ValueComponent = React.createClass

  displayName: 'ValueComponent'

  render: ->
    { br, div } = React.DOM

    value = @props.value

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
        'value main'
      else
        switch type
          when 'String' then 'value string'
          when 'Symbol' then 'value symbol'
          else 'value'

    div { className: 'value' },
      div { key: 'value', className: css_class },
        if type == 'String'
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
        else
          display
        div { key: 'type', className: 'type' },
          type

module.exports = ValueComponent
