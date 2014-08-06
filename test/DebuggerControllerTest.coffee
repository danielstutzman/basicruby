DebuggerController = require '../coffee-istanbul/DebuggerController.js'
helper             = require '../test/helper.coffee'

{ click } = helper

describe 'DebuggerController', ->
  it 'renders a working close button', ->
    div = document.createElement('div')
    div.id = 'debugger'
    document.body.appendChild div

    controller = new DebuggerController('puts 1', div, {}, {}, (->))
    controller.setup()
    controller.render()

    expect(div.querySelectorAll('.close-button').length).toBe 1

    helper.click(div.querySelectorAll('.close-button')[0])
    expect(div.parentNode).toBe null
