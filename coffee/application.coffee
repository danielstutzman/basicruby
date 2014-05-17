DebuggerController = require './DebuggerController.coffee'
SetupResizeHandler = require('./setup_resize_handler.coffee')

$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

solutionCodeMirror = null
solutionState = 'NONE' # or DEBUGGER or CODE-AND-DEBUGGER
forceResize = null
toggleSolutionState = (newState) ->
  if newState == solutionState
    solutionState = 'NONE'
  else
    solutionState = newState

  sectionDiv = document.getElementById('solution-section')
  sectionInnerDiv = sectionDiv.querySelector('.consistent-height')
  codeDiv = document.getElementById('solution-code-hider')
  demoButton = $one 'button.show-demo'
  solutionButton = $one 'button.show-solution'

  switch solutionState
    when 'NONE'
      sectionDiv.style.display = 'none'
      demoButton.classList.remove 'active'
      solutionButton.classList.remove 'active'
    when 'DEBUGGER'
      sectionDiv.style.display = 'block'
      SetupResizeHandler.resizeConsoleToFitHeight sectionInnerDiv
      codeDiv.style.display = 'none'
      document.querySelector('body').scrollTop =
        document.querySelector('body').scrollHeight
      demoButton.classList.add 'active'
      solutionButton.classList.remove 'active'
    when 'CODE-AND-DEBUGGER'
      sectionDiv.style.display = 'block'
      SetupResizeHandler.resizeConsoleToFitHeight sectionInnerDiv
      codeDiv.style.display = 'block'
      solutionCodeMirror.refresh()
      document.querySelector('body').scrollTop =
        document.querySelector('body').scrollHeight
      demoButton.classList.remove 'active'
      solutionButton.classList.add 'active'
  forceResize()

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.machine') # have to wait until dom is loaded to check
    for section in $all('.section')
      isInSolutionSection = (section.getAttribute('id') == 'solution-section')
      isInStretchSection = section.classList.contains('stretch-section')

      options =
        mode: 'ruby'
        lineNumbers: true
        autofocus: true
        readOnly: isInSolutionSection
      textarea = section.querySelector('textarea.code-editor')
      codeMirror = CodeMirror.fromTextArea textarea, options
      if isInSolutionSection
        solutionCodeMirror = codeMirror

      makeRetriever = (codeMirror) -> (-> codeMirror.getValue())
      retrieveNewCode = makeRetriever codeMirror
      $debuggerDiv = section.querySelector('div.debugger')
      $casesDiv = section.querySelector('div.cases')
      # the exerciseYaml global variable needs to be defined by the view
      new DebuggerController(
        retrieveNewCode, $debuggerDiv, $casesDiv, exerciseYaml).setup()

      if isInStretchSection
        forceResize = SetupResizeHandler.setupResizeHandler codeMirror

    if $one('button.show-demo')
      $one('button.show-demo').addEventListener 'click', ->
        toggleSolutionState 'DEBUGGER'
    if $one('button.show-solution')
      $one('button.show-solution').addEventListener 'click', ->
        toggleSolutionState 'CODE-AND-DEBUGGER'
