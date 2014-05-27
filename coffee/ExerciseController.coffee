AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
DebuggerController    = require './DebuggerController.coffee'
ExerciseComponent     = require './ExerciseComponent.coffee'

class ExerciseController
  constructor: ($div, featuresJson, exerciseJson, exerciseColor,
      pathForNextExercise, pathForNextRep, pathForVideo, pathForVideoPoster) ->
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
    @pathForVideo = pathForVideo
    @pathForVideoPoster = pathForVideoPoster
    @cases = @json.cases || [{}]
    @actualOutput = if @color == 'green' then [] else null
    @retrieveNewCode = null
    @showingSuccessPopup = false
    @showingYellowVideo = false

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
      pathForVideo: @pathForVideo
      pathForVideoPoster: @pathForVideoPoster
      showingSuccessPopup: @showingSuccessPopup
      showingYellowVideo: @showingYellowVideo
      doCommand:
        run: =>
          @handleRun()
          @checkForPassingTests()
        debug: => @handleDebug()
        allTestsPassed: => window.setTimeout (=> @handleAllTestsPassed()), 100
        next: if @pathForNextExercise == '' then null else (e) =>
          e.target.disabled = true
          window.location.href = @pathForNextExercise
        nextRep: if @pathForNextRep == '' then null else (e) =>
          e.target.disabled = true
          window.location.href = @pathForNextRep
        showSolution: => @handleShowSolution()
        closeSuccessPopup: => @showingSuccessPopup = false; @render()
        setPredictedOutput: (caseNum, newText) =>
          @cases[caseNum].predicted_output = newText
          @render()
          @checkForPassingTests()
        showYellowVideo: (smallBox) => @showingYellowVideo = true; @render()
        closeYellowVideo: => @showingYellowVideo = false; @render()
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
    features = _.extend @features, showNextExercise: false, showNextRep: false,
      showingSolution: false
    @_popupDebugger @retrieveNewCode(), features, {}

  handleShowSolution: ->
    features = _.extend @features,
      showNextExercise: false
      showNextRep: @pathForNextRep != ''
      showingSolution: true
    doCommand =
      nextExercise: (e) =>
        e.target.disabled = true
        window.location.href = @pathForNextExercise
      nextRep: (e) =>
        e.target.disabled = true
        window.location.href = @pathForNextRep
    @_popupDebugger @json.solution, features, doCommand

  _popupDebugger: (code, features, doCommand) ->
    newDiv = document.createElement('div')
    newDiv.className = 'debugger'
    document.body.appendChild newDiv
    new DebuggerController(code, newDiv, features, @json, doCommand).setup()

  checkForPassingTests: ->
    rtrim = (s) -> if s then s.replace(/\s+$/, '') else s
    join = (outputs) ->
      _.map(outputs, ((output) -> output[1])).join('')
    for case_, case_num in @cases
      case_.actual_matches_expected =
        if @color == 'blue'
          rtrim(join(case_.actual_output)) == rtrim(case_.predicted_output)
        else if @color == 'red' || @color == 'green'
          rtrim(join(case_.actual_output)) == rtrim(case_.expected_output.toString())
    if _.every(@cases, (case_) -> case_.actual_matches_expected)
      changeBackground = (i) =>
        for span in document.querySelectorAll('.passed')
          span.style.opacity = if (i % 2 == 1) then '1.0' else '0.0'
        if i > 0
          window.setTimeout (-> changeBackground(i - 1)), 300
        else
          @showingSuccessPopup = true
          @render()
      changeBackground 5

module.exports = ExerciseController
