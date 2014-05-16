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
    # the exerciseYaml global variable needs to be defined by the view
    new DebuggerController(
      retrieveNewCode, $debuggerDiv, $casesDiv, exerciseYaml).setup()

    setupResizeHandler codeMirror
