DebuggerController = require './DebuggerController.coffee'
setupResizeHandler = require('./setup_resize_handler.coffee').setupResizeHandler

$one = (selector) -> document.querySelector(selector)

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.machine') # have to wait until dom is loaded to check
    options =
      mode: 'ruby'
      lineNumbers: true
      autofocus: true
    codeMirror = CodeMirror.fromTextArea($one('.code-editor'), options)

    retrieveNewCode = -> codeMirror.getValue()
    $debuggerDiv = $one 'div.debugger'
    $casesDiv = $one 'div.cases'
    features =
      showStepButton: true
      showRunButton: true
      showPartialCalls: false
      showVariables: false
      showInstructions: true
      showConsole: true
      highlightTokens: false
    new DebuggerController(
      retrieveNewCode, $debuggerDiv, $casesDiv, features).setup()

    setupResizeHandler codeMirror
