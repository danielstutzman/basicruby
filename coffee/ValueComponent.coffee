ValueComponent = React.createClass

  displayName: 'ValueComponent'

  render: ->
    { div } = React.DOM

    value = @props.value
    type = value.$class().$to_s()

    css_class =
      switch type
        when 'String' then 'string'
        else ''
    display =
      switch type
        when 'String' then value.$to_s()
        else value.$inspect()

    if display == 'main'
      css_class += ' main'

    if type == 'String' && display == ''
      css_class += ' empty'

    div { className: 'value' },
      div { key: 'value', className: css_class },
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
            else type

module.exports = ValueComponent
