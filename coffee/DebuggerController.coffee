AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
DebuggerComponent     = require './DebuggerComponent.coffee'
RubyCodeHighlighter   = require './RubyCodeHighlighter.coffee'

class DebuggerController
  constructor: (code, $div, features, exerciseJson, exerciseDoCommand) ->
    @code = code
    @$div = $div
    @features = features
    @exerciseDoCommand = exerciseDoCommand
    @spool = null
    @highlighter = null
    @mostRecentNumRenderCall = 0
    @pendingStdin = null
    @cases =
      currentCaseNum: null
      currentCaseStage: null
      cases: _.map exerciseJson['cases'], (_case) ->
        input: if _case.input != undefined then _case.input.toString()
        expectedOutput: _case.expected_output.toString()

  setup: ->
    @handleTurnPowerOn()
    @render()

  render: ->
    numRenderCall = @mostRecentNumRenderCall += 1
    props =
      isRunButtonDepressed:   @isRunButtonDepressed
      isConsoleFakeSelected:  @isConsoleFakeSelected
      features:     @features
      buttons:      @spool?.visibleState()
      instructions: @highlighter?.visibleState()
      interpreter:  @interpreter?.visibleState()
      pendingStdin: @pendingStdin
      doCommand:
        close:         => @$div.parentNode.removeChild @$div
        nextExercise:  @exerciseDoCommand.nextExercise
        nextRep:       @exerciseDoCommand.nextRep
        nextPosition:  => @handleClickNextPosition.apply this, []
        run:           => @handleClickRun.apply          this, []
        doChangeInput: (newText) => @pendingStdin = newText; @render()
        doSubmitInput: (newText) => @pendingStdin = null; @handleInput newText
      animationFinished: =>
        if numRenderCall == @mostRecentNumRenderCall
          @handleNextBytecode.apply this, []
    React.renderComponent DebuggerComponent(props), @$div

  handleTurnPowerOn: ->
    code = @code
    try
      bytecodes = AstToBytecodeCompiler.compile code
    catch e
      if e.name == 'SyntaxError'
        @interpreter = visibleState: ->
          output: [['stderr', "SyntaxError: #{e.message}\n"]]
      else if e.name == 'DebuggerDoesntYetSupport'
        @interpreter = visibleState: ->
          output: [['stderr', "DebuggerDoesntYetSupport: #{e.message}\n"]]
      else
        throw e
    if bytecodes
      @spool = new BytecodeSpool bytecodes
      @highlighter = new RubyCodeHighlighter code, @features.highlightTokens
      @interpreter = new BytecodeInterpreter()

    if @spool
      # run step until the first position
      @spool.queueRunUntil 'NEXT_POSITION'
      bytecode = @spool.getNextBytecode
      @highlighter.interpret bytecode
    @render()

  handleClickNextPosition: ->
    @spool.queueRunUntil 'NEXT_POSITION'
    @render()

  handleClickRun: ->
    @spool.queueRunUntil 'DONE'
    @render()

  handleNextBytecode: ->
    if @spool && @highlighter && @interpreter
      if @interpreter.isAcceptingInput()
        if @cases.currentCaseNum != null &&
           @cases.currentCaseStage == 'RUNNING'
          @cases.currentCaseStage = 'READY_FOR_INPUT'
          @handleRunTestCases()
      else
        bytecode = @spool.getNextBytecode @interpreter.isResultTruthy
        if bytecode
          @highlighter.interpret bytecode

          try
            @interpreter.interpret bytecode
          catch e
            if e.name == 'ProgramTerminated'
              @spool.terminateEarly()
            else
              throw e

          if @interpreter.isAcceptingInput()
            @pendingStdin = ''
          @render()

          if @spool.isDone() && @cases.currentCaseNum != null &&
             @cases.currentCaseStage == 'RUNNING'
            @cases.currentCaseStage = 'PROGRAM_IS_DONE'
            @handleRunTestCases()

  handleInput: (text) ->
    @interpreter.setInput text
    @handleNextBytecode()

module.exports = DebuggerController
