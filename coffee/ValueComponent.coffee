type           = React.PropTypes

ValueComponent = React.createClass

  displayName: 'ValueComponent'

  # one prop: value, which could be of any type

  render: ->
    { div } = React.DOM

    if typeof(@props.value) == 'string'
      if @props.value == ''
        div
          className: 'empty-string-value'
          "empty\nstring"
      else
        div
          className: 'string-value'
          @props.value
    else
      from_inspect = @props.value.$inspect()
      if from_inspect == 'main'
        div
          className: 'main'
          'main'
      else
        div
          className: ''
          @props.value.$inspect()

module.exports = ValueComponent
