DebuggerController = require '../coffee-istanbul/DebuggerController.js'

describe 'DebuggerController', ->
  it 'renders a close button', ->
    div = document.createElement('div')
    div.id = 'debugger'
    document.body.appendChild div

    controller = new DebuggerController('puts 1', div, {}, {}, (->))
    controller.setup()
    controller.render()

    expect(document.querySelectorAll('.close-button').length).toBe 1
    document.body.removeChild div
