AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'
DebuggerController    = require './DebuggerController.coffee'
ExerciseComponent     = require './ExerciseComponent.coffee'

class ExerciseController
  constructor: ($div, featuresJson, exerciseId, exerciseJson, exerciseColor,
      pathForNextExercise, pathForNextRep) ->
    @$div = $div
    exists = (feature) -> feature in featuresJson
    @features =
      showStepButton:   exists 'step'
      showRunButton:    exists 'run'
      showPartialCalls: exists 'partial_calls'
      showVariables:    exists 'vars'
      showHeapToggle:   exists 'heap_toggle'
      showInstructions: exists 'instructions'
      showConsole:      exists 'console'
      highlightTokens:  exists 'tokens'
    @exerciseId          = exerciseId
    @json                = exerciseJson
    @color               = exerciseColor
    @pathForNextExercise = pathForNextExercise
    @pathForNextRep      = pathForNextRep
    @cases               = @json.cases || [{}]
    @actualOutput        = if @color == 'green' then [] else null
    @retrieveNewCode     = null
    @popup               = null

  setup: ->
    callback = =>
      options =
        mode: 'ruby'
        lineNumbers: true
        autofocus: true
        readOnly: false
      textarea = @$div.querySelector('textarea.code')
      isMobileSafari = ->
         navigator.userAgent.match(/(iPod|iPhone|iPad)/) &&
         navigator.userAgent.match(/AppleWebKit/)
      if isMobileSafari()
        @retrieveNewCode = -> textarea.value
      else
        codeMirror = CodeMirror.fromTextArea textarea, options
        makeRetriever = (codeMirror) -> (-> codeMirror.getValue())
        @retrieveNewCode = makeRetriever codeMirror

      if @cases && @cases[0] && @cases[0].code
        for textareaTests in @$div.querySelectorAll('textarea.expected')
          options =
            mode: 'ruby'
            lineNumbers: true
            readOnly: 'nocursor'
            lineWrapping: true
          CodeMirror.fromTextArea textareaTests, options
    @render callback

  render: (callback) ->
    props =
      code: @json.code || ''
      color: @color
      cases: @cases
      popup: @popup
      doCommand:
        run: =>
          @handleRun()
          @checkForPassingTests()
        debug: => @handleDebug()
        allTestsPassed: => window.setTimeout (=> @handleAllTestsPassed()), 100
        next: if @pathForNextExercise == '' then null else (e) =>
          e.target.disabled = true
          @_sendPostMarkComplete @pathForNextExercise
        nextRep: if @pathForNextRep == '' then null else (e, success) =>
          e.target.disabled = true
          if success
            @_sendPostMarkComplete @pathForNextRep
          else
            window.location.href = @pathForNextRep
        showSolution: => @handleShowSolution()
        closePopup: => @popup = null; @render()
        setPredictedOutput: (caseNum, newText) =>
          @cases[caseNum].predicted_output = newText
          @render()
          isCaseFinished = (case_) -> case_.predicted_output != undefined &&
                                      case_.actual_output != undefined
          if _.every @cases, isCaseFinished
            @checkForPassingTests()
    React.renderComponent ExerciseComponent(props), @$div, callback

  handleRun: ->
    code = @retrieveNewCode()
    allTestCode = _.map(@cases, (case_) -> case_.code || '').join('')
    for case_ in @cases
      case_.inputLineNum = 0
      try
        if case_.code
          match = /^def (test_[a-zA-Z0-9_]*)\n/.exec case_.code
          throw "Case doesn't start with def test_" if match == null
          test_name = match[1]
          bytecodes = AstToBytecodeCompiler.compile [
            ['YourCode', code],
            ['TestCode', allTestCode],
            ['Main', "__run_test(:#{test_name})"]
          ]
        else
          bytecodes = AstToBytecodeCompiler.compile [['YourCode', code]]
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
        i = 0
        until @spool.isDone()
          i += 1
          if i > 10000
            throw "Interpreter seems to be stuck in a loop"
          bytecode = @spool.getNextBytecode()
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
      case_.passed =
        if @color == 'blue'
          rtrim(join(case_.actual_output)) == rtrim(case_.predicted_output)
        else if @color == 'red' || @color == 'green'
          if case_.expected_output
            rtrim(join(case_.actual_output)) ==
              rtrim(case_.expected_output.toString())
          else if case_.code && case_.actual_output.length > 0
            firstLine = case_.actual_output[0][1]
            /^test[a-zA-Z0-9_]+ PASSED\n/.exec(firstLine)
    passed = _.every(@cases, (case_) -> case_.passed)
    changeBackground = (i, selector, popup) =>
      for span in document.querySelectorAll(selector)
        span.style.opacity = if (i % 2 == 0) then '1.0' else '0.0'
      if i > 0
        window.setTimeout (-> changeBackground(i - 1, selector, popup)), 300
      else
        @popup = popup
        @render()
    if passed
      changeBackground 5, '.passed', 'PASSED'
    else if !passed && @color == 'blue'
      changeBackground 5, '.failed', 'FAILED'

  _sendPostMarkComplete: (nextUrl) ->
    document.body.innerHTML += "
      <form id='fake-form' method='post' action='/post/mark_complete'>
        <input type='hidden' name='exercise_id' value='#{@exerciseId}'>
        <input type='hidden' name='next_url' value='#{nextUrl}'>
      </form>"
    document.getElementById('fake-form').submit()

module.exports = ExerciseController
