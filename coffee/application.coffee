DebuggerAnimator   = require './DebuggerAnimator.coffee'
setupResizeHandler = require('./setup_resize_handler.coffee').setupResizeHandler

$one = (selector) -> document.querySelector(selector)

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.machine') # have to wait until dom is loaded to check
    options =
      mode: 'ruby'
      lineNumbers: true
      autofocus: true
    codeMirror = CodeMirror.fromTextArea($one('.code-editor'), options)
    (new DebuggerAnimator(codeMirror)).run()
    setupResizeHandler codeMirror
