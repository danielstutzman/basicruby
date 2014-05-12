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
        'main'
      else
        switch type
          when 'String' then 'string'
          when 'Symbol' then 'symbol'
          else ''

    div { className: 'value' },
      div { key: 'value', className: css_class },
        if type == 'String'
          lines = display.split("\n")
          _.map lines, (line, i) ->
            div { key: "line#{i}", className: 'line' },
              if line == ''
                div { className: 'empty-line' }
              else
                line
              if i < lines.length - 1
                br {}
        else
          display
      if display.length > 3
        div { key: 'type', className: 'type' },
          type
      else
        div { key: 'type', className: 'type', title: type },
          switch type
            when 'String'   then 'Str.'
            when 'Numeric'  then 'Num.'
            when 'Boolean'  then 'Bool.'
            when 'NilClass' then 'Nil.'
            when 'Object'   then 'Obj.'
            when 'Symbol'   then 'Sym.'
            else type

module.exports = ValueComponent
