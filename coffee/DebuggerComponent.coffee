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
    isOn:              type.bool.isRequired
    features:          type.object.isRequired
    buttons:           type.object
    instructions:      type.object
    interpreter:       type.object
    doCommand:         type.object.isRequired
    animationFinished: type.func.isRequired

  render: ->
    { br, button, div, label, span } = React.DOM

    finishedComponents = {}
    animationFinished = (name) =>
      finishedComponents[name] = true
      if _.keys(finishedComponents).length == 3
        animationFinished = -> console.log 'BLOCKED'
        window.setTimeout @props.animationFinished, 0

    div
      className: 'machine ' + (if @props.isOn then 'on ' else 'off ')

      div
        className: 'buttons'
        if @props.features.showStepButton
          button
            className: 'step ' + (if @props.buttons?.breakpoint ==
              'NEXT_POSITION' && @props.buttons?.numStepsQueued >
              0 then 'active ' else '')
            onClick: => @props.doCommand.nextPosition()
            disabled: !@props.isOn || @props.buttons?.isDone
            "#{RIGHT_TRIANGLE} Step"
        if @props.features.showRunButton
          button
            className: 'fast-forward ' + (if @props.buttons?.breakpoint ==
              'DONE' && @props.buttons?.numStepsQueued >
              0 then 'active ' else '')
            onClick: => @props.doCommand.run()
            disabled: !@props.isOn || @props.buttons?.isDone
            "#{RIGHT_TRIANGLE}#{RIGHT_TRIANGLE} Run"
        button
          className: 'power ' + (if @props.isOn then 'active ' else '')
          onClick: => @props.doCommand.togglePower()
          "#{POWER_SYMBOL} Power"

      if @props.features.showInstructions
        InstructionsComponent
          code:             @props.instructions?.code
          currentLine:      @props.instructions?.currentLine
          currentCol:       @props.instructions?.currentCol
          highlightedRange:
            @props.features.highlightTokens &&
              @props.instructions?.highlightedRange || null
          highlightedLineNum:
            !@props.features.highlightTokens &&
              @props.instructions?.highlightedLineNum || null
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
          acceptingInput: @props.interpreter?.acceptingInput
          doInput: (text) => @props.doCommand.doInput text
          animationFinished: -> animationFinished 'ConsoleComponent'
      else
        animationFinished 'ConsoleComponent'

      br { clear: 'all' }

module.exports = DebuggerComponent
