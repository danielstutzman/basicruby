AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
ExerciseComponent     = require './ExerciseComponent.coffee'

class ExerciseController
  constructor: ($div, featuresJson, exerciseJson, exerciseColor,
      pathForNextExercise, pathForNextRep) ->
    @$div = $div
    exists = (feature) -> feature in featuresJson
    @features =
      showStepButton:   exists 'step'
      showRunButton:    exists 'run'
      showPartialCalls: exists 'partial_calls'
      showVariables:    exists 'vars'
      showInstructions: exists 'instructions'
      showConsole:      exists 'console'
      highlightTokens:  exists 'tokens'
    @json = exerciseJson
    @color = exerciseColor
    @pathForNextExercise = pathForNextExercise
    @pathForNextRep = pathForNextRep
    @actualOutput = if @color == 'green' then [] else null
    @retrieveNewCode = null

  setup: ->
    callback = =>
      options =
        mode: 'ruby'
        lineNumbers: true
        autofocus: true
        readOnly: false
      textarea = @$div.querySelector('textarea.code')
      codeMirror = CodeMirror.fromTextArea textarea, options
      makeRetriever = (codeMirror) -> (-> codeMirror.getValue())
      @retrieveNewCode = makeRetriever codeMirror
      if @color == 'red'
        @handleRun()
    @render callback

  render: (callback) ->
    props =
      code: @json.code || ''
      color: @color
      actualOutput: @actualOutput
      expectedOutput:
        if @json.cases then @json.cases[0].expected_output.toString() else null
      doCommand:
        run: => @handleRun()
        next: if @pathForNextExercise == '' then null else (e) =>
          e.target.disabled = true
          window.location.href = @pathForNextExercise
        nextRep: if @pathForNextRep == '' then null else (e) =>
          e.target.disabled = true
          window.location.href = @pathForNextRep
    React.renderComponent ExerciseComponent(props), @$div, callback

  handleRun: ->
    code = @retrieveNewCode()
    try
      bytecodes = AstToBytecodeCompiler.compile code
    catch e
      if e.name == 'SyntaxError'
        @actualOutput = [['stderr', "SyntaxError: #{e.message}\n"]]
      else if e.name == 'DebuggerDoesntYetSupport'
        @actualOutput = [['stderr', "DebuggerDoesntYetSupport: #{e.message}\n"]]
      else
        throw e
    if bytecodes
      @spool = new BytecodeSpool bytecodes
      @interpreter = new BytecodeInterpreter()
    if @spool
      @spool.queueRunUntil 'DONE'
      while !@spool.isDone()
        bytecode = @spool.getNextBytecode @interpreter.isResultTruthy
        try
          @interpreter.interpret bytecode
        catch e
          if e.name == 'ProgramTerminated'
            @spool.terminateEarly()
          else
            throw e
      @actualOutput = @interpreter.visibleState().output
    @render()

module.exports = ExerciseController
