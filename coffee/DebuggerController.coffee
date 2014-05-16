AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
CasesComponent        = require './CasesComponent.coffee'
DebuggerComponent     = require './DebuggerComponent.coffee'
RubyCodeHighlighter   = require './RubyCodeHighlighter.coffee'

class DebuggerController
  constructor: (retrieveNewCode, $debuggerDiv, $casesDiv, features) ->
    @retrieveNewCode = retrieveNewCode
    @$debuggerDiv = $debuggerDiv
    @$casesDiv = $casesDiv
    @features = features
    @isOn = false
    @isPowerButtonDepressed = false
    @isRunButtonDepressed = false
    @isConsoleFakeSelected = false
    @spool = null
    @highlighter = null
    @mostRecentNumRenderCall = 0
    @pendingStdin = null
    @cases = {
      currentCaseNum: null,
      currentCaseStage: null,
      cases: [
        { input: '5\n1', actualOutput: '25', expectedOutput: '25' },
        { input: '4\n1', actualOutput: '16', expectedOutput: '16' },
      ]
    }

  setup: ->
    @render()

  render: ->
    numRenderCall = @mostRecentNumRenderCall += 1
    props =
      isOn:         @isOn
      isPowerButtonDepressed: @isPowerButtonDepressed
      isRunButtonDepressed:   @isRunButtonDepressed
      isConsoleFakeSelected:  @isConsoleFakeSelected
      features:     @features
      buttons:      @spool?.visibleState()
      instructions: @highlighter?.visibleState()
      interpreter:  @interpreter?.visibleState()
      pendingStdin: @pendingStdin
      doCommand:
        togglePower:   => @handleTogglePower.apply       this, []
        nextPosition:  => @handleClickNextPosition.apply this, []
        run:           => @handleClickRun.apply          this, []
        doChangeInput: (newText) => @pendingStdin = newText; @render()
        doSubmitInput: (newText) => @pendingStdin = null; @handleInput newText
      animationFinished: =>
        if numRenderCall == @mostRecentNumRenderCall
          @handleNextBytecode.apply this, []
    React.renderComponent DebuggerComponent(props), @$debuggerDiv
    props =
      cases:        @cases
      runTestCases: => @handleRunTestCases.apply this, []
    React.renderComponent CasesComponent(props), @$casesDiv

  handleTogglePower: ->
    if @isOn
      @isOn = false
      @handleTurnPowerOff()
    else
      @isOn = true
      @handleTurnPowerOn()

  handleTurnPowerOn: ->
    code = @retrieveNewCode()
    try
      bytecodes = AstToBytecodeCompiler.compile code
    catch e
      if e.name == 'SyntaxError'
        @interpreter = visibleState: ->
          output: ["SyntaxError: #{e.message}\n"]
      else if e.name == 'DebuggerDoesntYetSupport'
        @interpreter = visibleState: ->
          output: ["DebuggerDoesntYetSupport: #{e.message}\n"]
      else
        throw e
    if bytecodes
      @spool = new BytecodeSpool bytecodes
      @highlighter = new RubyCodeHighlighter code
      @interpreter = new BytecodeInterpreter()

    if @spool
      # run step until the first position
      @spool.queueRunUntil 'NEXT_POSITION'
      bytecode = @spool.getNextBytecode
      @highlighter.interpret bytecode
    @render()

  handleTurnPowerOff: ->
    @spool = null
    @highlighter = null
    @interpreter = null
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
          @interpreter.interpret bytecode
          if @interpreter.isAcceptingInput()
            @pendingStdin = ''
          @render()
          if @spool.isDone() && @cases.currentCaseNum != null
            @cases.currentCaseStage = 'PROGRAM_IS_DONE'
            @handleRunTestCases()


  handleInput: (text) ->
    @interpreter.setInput text
    @handleNextBytecode()

  handleRunTestCases: ->
    if @cases.currentCaseNum == null
      for case_ in @cases.cases
        case_.actualOutput = null
      @cases.currentCaseNum = 0
      @cases.currentCaseStage = 'HIGHLIGHTING'
      @cases.nextInputLineNum = 0

    oldStage = @cases.currentCaseStage
    switch oldStage
      when 'HIGHLIGHTING'
        @cases.currentCaseStage = 'POST_HIGHLIGHT_WAIT'
        millis = 400

      when 'POST_HIGHLIGHT_WAIT'
        @isPowerButtonDepressed = true

        @cases.currentCaseStage = 'DEPRESSING_POWER_BUTTON'
        millis = 100

      when 'DEPRESSING_POWER_BUTTON'
        @isPowerButtonDepressed = false
        @isOn = true

        code = @retrieveNewCode()
        bytecodes = AstToBytecodeCompiler.compile code
        @spool = new BytecodeSpool bytecodes
        @highlighter = new RubyCodeHighlighter code
        @interpreter = new BytecodeInterpreter()

        # run step until the first position
        @spool.queueRunUntil 'NEXT_POSITION'
        bytecode = @spool.getNextBytecode
        @highlighter.interpret bytecode

        @cases.currentCaseStage = 'SHOWING_STARTED_MACHINE'
        millis = 700

      when 'SHOWING_STARTED_MACHINE'
        @isRunButtonDepressed = true

        @cases.currentCaseStage = 'DEPRESSING_RUN_BUTTON'
        millis = 100

      when 'DEPRESSING_RUN_BUTTON'
        @isRunButtonDepressed = false
        @spool.queueRunUntil 'DONE'

        @cases.currentCaseStage = 'RUNNING'
        millis = null # wait until something calls handleRunTestCase again

      when 'READY_FOR_INPUT'
        # show empty focused blinking stdin box

        @cases.currentCaseStage = 'SHOW_INPUT'
        millis = 500

      when 'SHOW_INPUT'
        lines = @cases.cases[@cases.currentCaseNum].input.split("\n")
        @pendingStdin = lines[@cases.nextInputLineNum] + "\n"
        @cases.nextInputLineNum += 1

        @cases.currentCaseStage = 'SUBMIT_INPUT'
        millis = 800

      when 'SUBMIT_INPUT'
        @handleInput @pendingStdin
        @pendingStdin = null

        @cases.currentCaseStage = 'RUNNING'
        millis = null # wait until something calls handleRunTestCase again

      when 'PROGRAM_IS_DONE'
        @cases.currentCaseStage = 'WAIT_BEFORE_FAKE_SELECT'
        millis = 800

      when 'WAIT_BEFORE_FAKE_SELECT'
        @isConsoleFakeSelected = true

        @cases.currentCaseStage = 'FAKE_SELECT_CONSOLE'
        millis = 200

      when 'FAKE_SELECT_CONSOLE'
        @isConsoleFakeSelected = false

        @cases.currentCaseStage = 'FAKE_PASTE_OUTPUT'
        millis = 800

      when 'FAKE_PASTE_OUTPUT'
        output = @interpreter.getStdout().replace /\n$/, ''
        @cases.cases[@cases.currentCaseNum].actualOutput = output

        @cases.currentCaseStage = 'WAIT_AFTER_FAKE_PASTE'
        millis = 600

      when 'WAIT_AFTER_FAKE_PASTE'
        @isPowerButtonDepressed = true

        @cases.currentCaseStage = 'TURNING_OFF'
        millis = 100

      when 'TURNING_OFF'
        @isPowerButtonDepressed = false
        @isOn = false
        @spool = null
        @highlighter = null
        @interpreter = null

        @cases.currentCaseStage = 'TURNED_OFF'
        millis = 1000

      when 'TURNED_OFF'
        if @cases.currentCaseNum < @cases.cases.length - 1
          @cases.currentCaseNum += 1
          @cases.currentCaseStage = 'HIGHLIGHTING'
          @cases.nextInputLineNum = 0
          millis = 600
        else
          @cases.currentCaseNum = null
          @cases.currentCaseStage = 'DONE'
          @cases.nextInputLineNum = 0
          millis = null # don't start again

    if millis
      window.setTimeout (=> @handleRunTestCases.apply this, []), millis
    @render()

module.exports = DebuggerController
