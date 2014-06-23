ConsoleComponent      = require './ConsoleComponent.coffee'
HeapComponent         = require './HeapComponent.coffee'
InstructionsComponent = require './InstructionsComponent.coffee'
VariablesComponent    = require './VariablesComponent.coffee'
PartialCallsComponent = require './PartialCallsComponent.coffee'

POWER_SYMBOL   = '\u233d'
RIGHT_TRIANGLE = '\u25b6'
RELOAD_ICON    = "\u27f3"
RIGHT_ARROW    = "\u279c"
X_FOR_CLOSE    = "\u00d7"
type           = React.PropTypes

DebuggerComponent = React.createClass

  displayName: 'DebuggerComponent'

  propTypes:
    features:            type.object.isRequired
    buttons:             type.object
    instructions:        type.object
    interpreter:         type.object
    pendingStdin:        type.string
    numCharsToOutput:    type.number.isRequired
    currentScrollTop:    type.number.isRequired
    doCommand:           type.object.isRequired

  getInitialState: ->
    showHeap: false

  render: ->
    { a, button, div, h1, label, span } = React.DOM

    featuresList = _.keys(@props.features).filter((key) => @props.features[key])

    div { className: featuresList.join(' ') },
      a
        className: 'close-button'
        href: '#'
        onClick: (e) => e.preventDefault(); @props.doCommand.close()
        X_FOR_CLOSE

      if @props.features.showingSolution
        h1 { className: 'solution' }, 'Solution'

      div
        className: 'instructions-buttons'
        if @props.features.showStepButton
          button
            className: 'step ' + (if @props.buttons?.breakpoint ==
              'NEXT_LINE' && @props.buttons?.numStepsQueued >
              0 then 'active ' else '')
            onClick: => @props.doCommand.nextLine()
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
          currentScrollTop: @props.currentScrollTop

      if @props.features.showPartialCalls
        PartialCallsComponent
          partialCalls: @props.interpreter?.partialCalls || []
          numPartialCallExecuting: @props.interpreter?.numPartialCallExecuting

      if @props.features.showVariables
        if @state.showHeap
          HeapComponent
            varsStack: @props.interpreter?.varsStack
            doToggleHeap: => @setState showHeap: false
        else
          VariablesComponent
            varsStack: @props.interpreter?.varsStack
            showHeapToggle: @props.features.showHeapToggle
            doToggleHeap: => @setState showHeap: true

      if @props.features.showConsole
        ConsoleComponent
          output: @props.interpreter?.output
          numCharsToOutput: @props.numCharsToOutput
          pendingStdin: @props.pendingStdin
          doChangeInput: (text) => @props.doCommand.doChangeInput text
          doSubmitInput: (text) => @props.doCommand.doSubmitInput text

      div { className: 'exercise-buttons' },
        if @props.features.showNextRep
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null
            onClick: (e) => @props.doCommand.nextRep e
            "#{RELOAD_ICON} Try another one"
        if @props.features.showNextExercise
          button
            className: 'next'
            disabled: @props.doCommand.nextExercise == null
            onClick: (e) => @props.doCommand.nextExercise e
            "#{RIGHT_ARROW} Go on"

module.exports = DebuggerComponent
