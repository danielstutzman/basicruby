DebuggerController = require './DebuggerController.coffee'
ExerciseController = require './ExerciseController.coffee'
ExerciseComponent  = require './ExerciseComponent.coffee'
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
  explanationDiv = sectionDiv.querySelector('p.demo-explanation')

  switch solutionState
    when 'NONE'
      sectionDiv.style.display = 'none'
      demoButton.classList.remove 'active' if demoButton
      solutionButton.classList.remove 'active'
    when 'DEBUGGER'
      sectionDiv.style.display = 'block'
      SetupResizeHandler.resizeConsoleToFitHeight sectionInnerDiv
      codeDiv.style.display = 'none'
      explanationDiv.style.display = 'block'
      document.querySelector('body').scrollTop =
        document.querySelector('body').scrollHeight
      demoButton.classList.add 'active' if demoButton
      solutionButton.classList.remove 'active'
    when 'CODE-AND-DEBUGGER'
      sectionDiv.style.display = 'block'
      SetupResizeHandler.resizeConsoleToFitHeight sectionInnerDiv
      codeDiv.style.display = 'block'
      explanationDiv.style.display = 'none'
      solutionCodeMirror.refresh()
      document.querySelector('body').scrollTop =
        document.querySelector('body').scrollHeight
      demoButton.classList.remove 'active' if demoButton
      solutionButton.classList.add 'active'
  forceResize()

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.exercise') && !$one('div.exercise.purple')
    new ExerciseController($one('div.exercise'), featuresJson, exerciseJson,
      exerciseColor, pathForNextExercise, pathForNextRep).setup()

  # Fix bug where Mobile Safari landscape mode scrolls too far down the page
  window.addEventListener 'orientationchange', ->
    window.scrollTo 0, 1
