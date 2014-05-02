$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

resizeDivs = (w, h) ->
  width_code = w / 2
  width_machine = w / 2
  width_next_line = 65
  width_console = width_machine - width_next_line

  height_breadcrumbs = 31
  height_description = 102
  height_actions = 84
  height_total = h - height_breadcrumbs - height_description - height_actions
  height_code = height_total
  height_console = height_total
  height_next_line = height_total

  for div in $all('.code, .CodeMirror')
    div.style.width  = "#{width_code}px"
    div.style.height = "#{height_code}px"
  for div in $all('.machine .console')
    div.style.width  = "#{width_console}px"
    div.style.height = "#{height_console}px"
  for div in $all('.machine .next-line')
    div.style.height = "#{height_next_line}px"

setupResizeHandler = (code_mirror) ->
  oldW = 0
  oldH = 0
  isChanging = false
  resizeIfChanged = ->
    # if this doesn't work, can try <svg id='svg'
    #   xmlns='http://www.w3.org/2000/svg' version='1.1'
    #   style='display:none'></svg> and
    #   document.getElementById('svg').currentScale
    w = window.innerWidth - 50
    h = window.innerHeight - 200
    if w != oldW or h != oldH
      isChanging = true
      oldW = w
      oldH = h
    else if isChanging
      resizeDivs w, h
      code_mirror.refresh()
      isChanging = false
  window.setInterval resizeIfChanged, 500
  resizeIfChanged()
  resizeIfChanged()

# states: OFF, WAITING, RUNNING
class Machine

  constructor: (line_height, setTimeout, code_mirror) ->
    @state = 'OFF'
    @line_num_to_unhighlight = null
    @next_line = null
    @console_lines = []
    @line_height = line_height
    @setTimeout = setTimeout
    @code_mirror = code_mirror

  _getNextLineHTML: ->
    return '' if @next_line == null
    y = @code_mirror.heightAtLine(@next_line - 1)
    # y = (@next_line - 1) * @line_height
    "<div class='pointer' style='top: #{y}px'>&larr;</div>"

  _getConsoleHTML: ->
    return '' if @state == 'OFF'
    empty_lines = ('' for i in [1..20]).join('<br>')
    console_lines = @console_lines.join('<br>') + '<br>'
    cursor = "<div class='cursor'></div>"
    empty_lines + console_lines + cursor

  refreshDisplays: ->
    $one('.machine .next-line').innerHTML = @_getNextLineHTML()
    if @line_num_to_unhighlight != null
      @code_mirror.removeLineClass @line_num_to_unhighlight - 1,
        'text', 'current-line'
    if @next_line != null
      @code_mirror.addLineClass @next_line - 1, 'text', 'current-line'
      @line_num_to_unhighlight = @next_line

    $one('.machine .console').innerHTML = @_getConsoleHTML()
    $one('.machine .console').scrollTop =
      $one('.machine .console').scrollHeight

    $one('.machine button.fast-forward').disabled =
      (@state == 'OFF' || @next_line == null)

    if @state == 'OFF'
      $one('.machine button.power').classList.remove 'active'
    else
      $one('.machine button.power').classList.add 'active'

    if @state != 'RUNNING'
      $one('.machine button.fast-forward').classList.remove 'active'
    else
      $one('.machine button.fast-forward').classList.add 'active'

  clickPower: ->
    if @state == 'OFF'
      @state = 'WAITING'
      @next_line = 1
      @console_lines = []
    else
      @state = 'OFF'
      @next_line = null
      @console_lines = []
    @refreshDisplays()

  _doStep : ->
    if @next_line == 1
      @console_lines.push '1'
      @next_line = 2
    else if @next_line == 2
      @console_lines.push '2'
      @next_line = 3
    else if @next_line == 3
      @console_lines.push '3'
      @state = 'WAITING'
      @next_line = null

    @refreshDisplays()

  clickStep: ->
    return unless @state == 'WAITING'
    @_doStep()

  clickRun: ->
    return unless @state == 'WAITING'

    @state = 'RUNNING'
    doNextStep = =>
      @_doStep()
      if @next_line != null
        @setTimeout doNextStep, 1000
    doNextStep()

setupMachine = (code_mirror) ->
  setTimeout = (f, seconds) -> window.setTimeout(f, seconds)
  machine = new Machine(40, setTimeout, code_mirror)
  for button in $all('.machine button.power')
    button.addEventListener 'click', ->
      machine.clickPower()
  for button in $all('.machine button.fast-forward')
    button.addEventListener 'click', ->
      machine.clickRun()
  machine.refreshDisplays()

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.machine') # have to wait until dom is loaded to check
    options =
      mode: 'ruby'
      lineNumbers: true
      autofocus: true
    code_mirror = CodeMirror.fromTextArea($one('.code'), options)
    setupMachine code_mirror
    setupResizeHandler code_mirror
