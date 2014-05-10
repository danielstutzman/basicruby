type           = React.PropTypes

ValueComponent = React.createClass

  displayName: 'ValueComponent'

  # one prop: value, which could be of any type

  render: ->
    { div } = React.DOM

    value = @props.value
    switch typeof value
      when 'string'
        if value == ''
          div { className: 'empty-string-value' }, "empty\nstring"
        else
          div { className: 'string-value' }, value
      when 'boolean'
        if value == true
          div { className: 'true-value' }, 'true'
        else if value == false
          div { className: 'false-value' }, 'false'
      when 'object'
        if value == Opal.NIL
          div { className: 'nil-value' }, 'nil'
        else if value == Opal.top
          div { className: 'main' }, 'main'
        else
          div {}, value.$inspect()
      else
        div {}, value.$inspect()

module.exports = ValueComponent
