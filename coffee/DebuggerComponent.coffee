ConsoleComponent      = require './ConsoleComponent.coffee'
InstructionsComponent = require './InstructionsComponent.coffee'
VariablesComponent    = require './VariablesComponent.coffee'
PartialCallsComponent = require './PartialCallsComponent.coffee'

POWER_SYMBOL   = '\u233d'
RIGHT_TRIANGLE = '\u25b6'
type           = React.PropTypes

DebuggerComponent = React.createClass

  displayName: 'DebuggerComponent'

  propTypes:
    features:          type.object.isRequired
    buttons:           type.object
    instructions:      type.object
    interpreter:       type.object
    pendingStdin:      type.string
    doCommand:         type.object.isRequired
    animationFinished: type.func.isRequired

  render: ->
    { button, div, label, span } = React.DOM

    finishedComponents = {}
    animationFinished = (name) =>
      finishedComponents[name] = true
      if _.keys(finishedComponents).length == 3
        animationFinished = -> console.log 'BLOCKED'
        window.setTimeout @props.animationFinished, 0

    div {},
      button
        className: 'close-button'
        onClick: => @props.doCommand.close()
        'X'
      div
        className: 'buttons'
        if @props.features.showStepButton
          button
            className: 'step ' + (if @props.buttons?.breakpoint ==
              'NEXT_POSITION' && @props.buttons?.numStepsQueued >
              0 then 'active ' else '')
            onClick: => @props.doCommand.nextPosition()
            disabled: @props.buttons?.isDone
            "#{RIGHT_TRIANGLE} Step"
        if @props.features.showRunButton
          button
            className: 'fast-forward ' + (if @props.buttons?.breakpoint ==
              'DONE' && @props.buttons?.numStepsQueued >
              0 then 'active ' else '')
            onClick: => @props.doCommand.run()
            disabled: @props.buttons?.isDone
            "#{RIGHT_TRIANGLE}#{RIGHT_TRIANGLE} Run"

      if @props.features.showInstructions
        InstructionsComponent
          code:             @props.instructions?.code
          currentLine:      @props.instructions?.currentLine
          currentCol:       @props.instructions?.currentCol
          highlightedRange: @props.instructions?.highlightedRange
          animationFinished: -> animationFinished 'InstructionsComponent'
      else
        animationFinished 'InstructionsComponent'

      if @props.features.showPartialCalls
        PartialCallsComponent
          partialCalls: @props.interpreter?.partialCalls || []
          numPartialCallExecuting: @props.interpreter?.numPartialCallExecuting
          animationFinished: -> animationFinished 'PartialCallsComponent'
      else
        animationFinished 'PartialCallsComponent'

      if @props.features.showVariables
        VariablesComponent @props.interpreter

      if @props.features.showConsole
        ConsoleComponent
          output: @props.interpreter?.output
          pendingStdin: @props.pendingStdin
          doChangeInput: (text) => @props.doCommand.doChangeInput text
          doSubmitInput: (text) => @props.doCommand.doSubmitInput text
          animationFinished: -> animationFinished 'ConsoleComponent'
      else
        animationFinished 'ConsoleComponent'

module.exports = DebuggerComponent
