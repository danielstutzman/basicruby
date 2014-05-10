type           = React.PropTypes

NBSP = "\u00a0"

PartialCallsComponent = React.createClass

  displayName: 'PartialCallsComponent'

  propTypes:
    partial_calls: type.array.isRequired

  render: ->
    { div, table, tbody, td, th, thead, tr } = React.DOM

    calls = @props.partial_calls

    max_num_cols = 3
    for call in calls
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
                  when 0 then '1st Arg'
                  when 1 then '2nd Arg'
                  when 2 then '3rd Arg'
                  else        "#{arg_num + 1}th Arg"
            th { key: 'extra-space', className: 'extra-space' }

        tbody {},
          if calls.length == 0
            tr { key: 'data0' },
              td { key: 'receiver' }, NBSP
              td { key: 'method' }, NBSP
              td { key: 'arg0' }, NBSP
              td { key: 'extra-space', className: 'extra-space' }
  
          _.map calls, (call, call_num) ->
            tr { key: "data#{call_num}" },
              _.map call, (arg, arg_num) ->
                td { key: "arg#{arg_num}" },
                  if arg_num == 1 # method name
                    arg.$to_s()
                  else
                    arg.$inspect()
              _.times (max_num_cols - call.length), (unfilled_arg_num) ->
                td { key: "unfilled-arg#{unfilled_arg_num}" },
                  # if it's the 1st unfilled arg, but not the last partial call
                  if unfilled_arg_num == 0 && call_num < calls.length - 1
                    '...'
                  else
                    NBSP
              td { key: 'extra-space', className: 'extra-space' }
  
module.exports = PartialCallsComponent
