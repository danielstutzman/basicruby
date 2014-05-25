AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
DebuggerController    = require './DebuggerController.coffee'
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
    @cases = @json.cases || [{}]
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
      if @color == 'red' || @color == 'green'
        @handleRun()
    @render callback

  render: (callback) ->
    props =
      code: @json.code || ''
      color: @color
      cases: @cases
      doCommand:
        run: => @handleRun()
        debug: => @handleDebug()
        next: if @pathForNextExercise == '' then null else (e) =>
          e.target.disabled = true
          window.location.href = @pathForNextExercise
        nextRep: if @pathForNextRep == '' then null else (e) =>
          e.target.disabled = true
          window.location.href = @pathForNextRep
        showSolution: =>
          console.log 'show solution'
    React.renderComponent ExerciseComponent(props), @$div, callback

  handleRun: ->
    code = @retrieveNewCode()
    for case_ in @cases
      case_.inputLineNum = 0
      try
        bytecodes = AstToBytecodeCompiler.compile code
      catch e
        if e.name == 'SyntaxError'
          case_.actual_output = [['stderr', "SyntaxError: #{e.message}\n"]]
        else if e.name == 'DebuggerDoesntYetSupport'
          case_.actual_output =
            [['stderr', "DebuggerDoesntYetSupport: #{e.message}\n"]]
        else
          throw e

      if bytecodes
        @spool = new BytecodeSpool bytecodes
        @interpreter = new BytecodeInterpreter()
        @spool.queueRunUntil 'DONE'
        until @spool.isDone()
          bytecode = @spool.getNextBytecode @interpreter.isResultTruthy
          try
            @interpreter.interpret bytecode
          catch e
            if e.name == 'ProgramTerminated'
              @spool.terminateEarly()
            else
              throw e
          if @interpreter.isAcceptingInput()
            line = case_.input.toString().split("\n")[case_.inputLineNum] + "\n"
            @interpreter.setInput line
            case_.inputLineNum += 1
        case_.actual_output = @interpreter.getStdoutAndStderr()
    @render()

  handleDebug: ->
    newDiv = document.createElement('div')
    newDiv.className = 'debugger'
    document.body.appendChild newDiv
    new DebuggerController(@retrieveNewCode, newDiv, null, @features, @json).setup()

module.exports = ExerciseController
