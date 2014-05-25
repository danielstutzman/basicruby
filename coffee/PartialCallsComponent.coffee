ValueComponent = require './ValueComponent.coffee'
type           = React.PropTypes
NBSP           = "\u00a0"

PartialCallsComponent = React.createClass

  displayName: 'PartialCallsComponent'

  propTypes:
    partialCalls: type.array
    numPartialCallExecuting: type.number

  render: ->
    { div, table, tbody, td, th, thead, tr } = React.DOM

    calls = @props.partialCalls
    highlighted_call_num = @props.numPartialCallExecuting

    max_num_cols = 2
    for call, i in calls
      # append ... to the end of every partial call except the last one
      if i < calls.length - 1
        if call.length + 1 > max_num_cols
          max_num_cols = call.length + 1
      else
        if call.length > max_num_cols
          max_num_cols = call.length

    div
      className: 'partial-calls'
      table {},

        thead {},
          tr {},
            th { key: 'receiver' }, 'Receiver'
            th { key: 'method' }, 'Method'
            th
              key: 'extra-space'
              className: 'extra-space'
              colSpan: max_num_cols - 2 + 1 # 1 is for the extra space
              'Arguments'

        tbody {},
          if calls.length == 0
            tr { key: 'no-calls', className: 'no-calls' },
              td { key: 'receiver' }
              td { key: 'method' }
              td { key: 'extra-space', className: 'extra-space' }
  
          _.map calls, (call, call_num) ->
            tr
              key: "data#{call_num}"
              className: if call_num == highlighted_call_num then 'executing'
              _.map call, (arg, arg_num) ->
                td { key: "arg#{arg_num}" },
                  if arg_num == 1 && arg.$to_s() == '<<'
                    div { className: 'string-interpolation' },
                        'string interpolation'
                  else
                    ValueComponent value: arg
              _.times (max_num_cols - call.length), (unfilled_arg_num) ->
                td
                  key: "unfilled-arg#{unfilled_arg_num}"
                  className: 'unfilled'
                  # if it's the 1st unfilled arg, but not the last partial call
                  if unfilled_arg_num == 0 && call_num < calls.length - 1
                    '...'
                  else
                    NBSP
              td { key: 'extra-space', className: 'extra-space' }
  
module.exports = PartialCallsComponent
