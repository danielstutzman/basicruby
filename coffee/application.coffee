setupResizeHandler = require('./setup_resize_handler.coffee').setupResizeHandler
setupMachine       = require('./machine.coffee').setupMachine
window.compile     = require('./coffee/compile.coffee').compile

$one = (selector) -> document.querySelector(selector)

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.machine') # have to wait until dom is loaded to check
    options =
      mode: 'ruby'
      lineNumbers: true
      autofocus: true
    code_mirror = CodeMirror.fromTextArea($one('.code-editor'), options)
    setupMachine code_mirror
    setupResizeHandler code_mirror
