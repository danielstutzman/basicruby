ValueComponent = require './ValueComponent.coffee'
type           = React.PropTypes
NBSP           = "\u00a0"

PartialCallsComponent = React.createClass

  displayName: 'PartialCallsComponent'

  propTypes:
    partial_calls: type.array.isRequired
    num_partial_call_executing: type.number

  render: ->
    { div, table, tbody, td, th, thead, tr } = React.DOM

    calls = @props.partial_calls
    highlighted_call_num = @props.num_partial_call_executing

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
            _.times (max_num_cols - 2), (arg_num) ->
              th { key: "arg#{arg_num}" },
                switch arg_num
                  when 0 then '1st Arg.'
                  when 1 then '2nd Arg.'
                  when 2 then '3rd Arg.'
                  else        "#{arg_num + 1}th Arg."
            th { key: 'extra-space', className: 'extra-space' },
              if max_num_cols <= 2
                'Arguments'

        tbody {},
          if calls.length == 0
            tr { key: 'no-calls', className: 'no-calls' },
              td { key: 'receiver' }
              td { key: 'method' }
              td { key: 'arg0' }
              td { key: 'extra-space', className: 'extra-space' }
  
          _.map calls, (call, call_num) ->
            tr
              key: "data#{call_num}"
              className: if call_num == highlighted_call_num then 'executing'
              _.map call, (arg, arg_num) ->
                td { key: "arg#{arg_num}" },
                  if arg_num == 0 # receiver
                    ValueComponent value: arg
                  else if arg_num == 1
                    method_name = arg.$to_s()
                    if method_name == '<<'
                      div { className: 'string-interpolation' },
                        'string interpolation'
                    else
                      method_name
                  else
                    ValueComponent value: arg
              _.times (max_num_cols - call.length), (unfilled_arg_num) ->
                td { key: "unfilled-arg#{unfilled_arg_num}" },
                  # if it's the 1st unfilled arg, but not the last partial call
                  if unfilled_arg_num == 0 && call_num < calls.length - 1
                    '...'
                  else
                    NBSP
              td { key: 'extra-space', className: 'extra-space' }
  
module.exports = PartialCallsComponent
