AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
DebuggerComponent     = require './DebuggerComponent.coffee'
RubyCodeHighlighter   = require './RubyCodeHighlighter.coffee'

class DebuggerController
  constructor: (retrieveNewCode, $div) ->
    @retrieveNewCode = retrieveNewCode
    @$div = $div
    @isOn = false
    @spool = null
    @highlighter = null
    @mostRecentNumRenderCall = 0

  setup: ->
    @render()

  render: ->
    numRenderCall = @mostRecentNumRenderCall += 1
    props =
      isOn:         @isOn
      buttons:      @spool?.visibleState()
      instructions: @highlighter?.visibleState()
      interpreter:  @interpreter?.visibleState()
      doCommand:
        togglePower:  => @handleTogglePower.apply       this, []
        nextPosition: => @handleClickNextPosition.apply this, []
        run:          => @handleClickRun.apply          this, []
        doInput:      => @handleInput.apply             this, arguments
      animationFinished: =>
        if numRenderCall == @mostRecentNumRenderCall
          @handleNextBytecode.apply this, []
    React.renderComponent DebuggerComponent(props), @$div

  handleTogglePower: ->
    if @isOn
      @isOn = false
      @handleTurnPowerOff()
    else
      @isOn = true
      @handleTurnPowerOn()

  handleTurnPowerOn: ->
    window.clearTimeout @timeoutForNextBytecode
    code = @retrieveNewCode()
    try
      bytecodes = AstToBytecodeCompiler.compile code
    catch e
      if e.name == 'SyntaxError'
        @interpreter = visibleState: ->
          output: "SyntaxError: #{e.message}"
      else if e.name == 'DebuggerDoesntYetSupport'
        @interpreter = visibleState: ->
          output: "DebuggerDoesntYetSupport: #{e.message}"
      else
        throw e
    if bytecodes
      @spool = new BytecodeSpool bytecodes
      @highlighter = new RubyCodeHighlighter code
      @interpreter = new BytecodeInterpreter()
    @render()
    @handleClickNextPosition() # run step until the first position

  handleTurnPowerOff: ->
    @spool = null
    @highlighter = null
    @interpreter = null
    window.clearTimeout @timeoutForNextBytecode
    @render()

  handleClickNextPosition: ->
    window.clearTimeout @timeoutForNextBytecode
    @spool.queueRunUntil 'NEXT_POSITION'
    @render()

  handleClickRun: ->
    window.clearTimeout @timeoutForNextBytecode
    @spool.queueRunUntil 'DONE'
    @render()

  handleNextBytecode: ->
    if @spool && @highlighter && @interpreter &&
       !@interpreter.isAcceptingInput()
      bytecode = @spool.getNextBytecode @interpreter.isResultTruthy
      if bytecode
        @highlighter.interpret bytecode
        @interpreter.interpret bytecode
        @render()

  handleInput: (text) ->
    @interpreter.setInput text
    @handleNextBytecode()

module.exports = DebuggerController
