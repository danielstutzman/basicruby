AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
DebuggerComponent     = require './DebuggerComponent.coffee'
RubyCodeHighlighter   = require './RubyCodeHighlighter.coffee'

MILLIS_FOR_OUTPUT_CHAR         = 10
MILLIS_FOR_SCROLL_INSTRUCTIONS = 10
MILLIS_FOR_HIGHLIGHT           = 300
MILLIS_TO_HIGHLIGHT_CALL       = 500
MILLIS_TO_HIGHLIGHT_ADDED_ARG  = 500

class DebuggerController
  constructor: (code, $div, features, exerciseJson, exerciseDoCommand) ->
    @code = code
    @$div = $div
    @features = features
    @exerciseDoCommand = exerciseDoCommand
    @spool = null
    @highlighter = null
    @pendingStdin = null
    @numCharsToOutput = 1
    @currentScrollTop = 1
    @prevProps = {}

  setup: ->
    @handleTurnPowerOn()
    @render()

  countOutputChars: (output) ->
    numChars = 0
    if output
      for pair in output
        numChars += pair[1].length
    numChars

  render: ->
    props =
      features:     @features
      buttons:      @spool?.visibleState()
      instructions: @highlighter?.visibleState()
      interpreter:  @interpreter?.visibleState()
      pendingStdin: @pendingStdin
      numCharsToOutput: @numCharsToOutput
      currentScrollTop: @currentScrollTop
      doCommand:
        close:         => @$div.parentNode.removeChild @$div
        nextExercise:  @exerciseDoCommand.nextExercise
        nextRep:       @exerciseDoCommand.nextRep
        nextLine:      => @handleClickNextLine.apply this, []
        nextPosition:  => @handleClickNextPosition.apply this, []
        run:           => @handleClickRun.apply          this, []
        doChangeInput: (newText) => @pendingStdin = newText; @render()
        doSubmitInput: (newText) => @pendingStdin = null; @handleInput newText
    React.renderComponent DebuggerComponent(props), @$div
    @handleNextAnimationOrBytecode props

  handleNextAnimationOrBytecode: (props) ->
    currentLine = props.instructions?.currentLine
    calls1 =      props.interpreter?.partialCalls
    calls0 = @prevProps.interpreter?.partialCalls

    if props.instructions.highlightedRange
      window.setTimeout (=> @handleNextBytecode()), MILLIS_FOR_HIGHLIGHT
    else if @countOutputChars(props.interpreter?.output) >= props.numCharsToOutput
      @numCharsToOutput += 1
      window.setTimeout (=> @render()), MILLIS_FOR_OUTPUT_CHAR
    else if currentLine && currentLine != @currentScrollTop
      difference = currentLine - @currentScrollTop
      if currentLine > @currentScrollTop
        @currentScrollTop += _.max [0.125, difference / 3]
        @currentScrollTop = currentLine if @currentScrollTop > currentLine
      else
        @currentScrollTop += _.min [-0.125, difference / 3]
        @currentScrollTop = currentLine if @currentScrollTop < currentLine
      window.setTimeout (=> @render()), MILLIS_FOR_SCROLL_INSTRUCTIONS
    else if @features.showPartialCalls && props.numPartialCallExecuting != null &&
       props.numPartialCallExecuting != @prevProps.numPartialCallExecuting
      @prevProps = props
      window.setTimeout (=> @render()), MILLIS_TO_HIGHLIGHT_CALL
    else if @features.showPartialCalls &&
         calls1 && calls0 && calls1.length == calls0.length &&
         calls1[calls1.length - 1]?.length > calls0[calls0.length - 1]?.length
      @prevProps = props
      window.setTimeout (=> @render()), MILLIS_TO_HIGHLIGHT_ADDED_ARG
    else
      @prevProps = props
      @handleNextBytecode()

  handleTurnPowerOn: ->
    code = @code
    try
      bytecodes = AstToBytecodeCompiler.compile [['YourCode', code]]
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
      bytecode = @spool.getNextBytecode()
      @highlighter.interpret bytecode
      spoolCommand = @interpreter.interpret bytecode
      @spool.doCommand.apply @spool, spoolCommand
    @render()

  handleClickNextLine: ->
    @spool.queueRunUntil 'NEXT_LINE'
    @render()

  handleClickNextPosition: ->
    @spool.queueRunUntil 'NEXT_POSITION'
    @render()

  handleClickRun: ->
    @spool.queueRunUntil 'DONE'
    @render()

  handleNextBytecode: ->
    if @spool && @highlighter && @interpreter && !@interpreter.isAcceptingInput()
      bytecode = @spool.getNextBytecode()
      if bytecode
        @highlighter.interpret bytecode

        try
          spoolCommand = @interpreter.interpret bytecode
          @spool.doCommand.apply @spool, spoolCommand
        catch e
          if e.name == 'ProgramTerminated'
            @interpreter.undefineMethods()
            @spool.terminateEarly()
          else
            throw e

        if @interpreter.isAcceptingInput()
          @pendingStdin = ''
        @render()

  handleInput: (text) ->
    @interpreter.setInput text
    @handleNextBytecode()

module.exports = DebuggerController
