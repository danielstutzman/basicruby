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
  for div in $all('div.machine .console')
    div.style.width  = "#{width_console}px"
    div.style.height = "#{height_console}px"
  for div in $all('div.machine .next-line')
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
  MILLIS_FOR_BOLD = 300
  MILLIS_FOR_OUTPUT = 300
  MILLIS_FOR_OUTPUT_LETTER = 100
  MILLIS_FOR_UNBOLD = 500
  MILLIS_FOR_MOVED_ARROW = 500

  constructor: (line_height, setTimeout, code_mirror) ->
    @state = 'OFF'
    @line_num_to_unhighlight = null
    @next_line = null
    @line_height = line_height
    @setTimeout = setTimeout
    @code_mirror = code_mirror
    @being_bolded_marker = null

  _getNextLineHTML: ->
    return '' if @next_line == null
    y = @code_mirror.heightAtLine(@next_line - 1)
    # y = (@next_line - 1) * @line_height
    "<div class='pointer' style='top: #{y}px'>&larr;</div>"

  refreshDisplays: ->
    if @state == 'OFF'
      $one('div.machine').classList.add 'off'
    else
      $one('div.machine').classList.remove 'off'

    #$one('.machine .console').innerHTML = @_getConsoleHTML()
    #$one('.machine .console').scrollTop =
    #  $one('.machine .console').scrollHeight

    $one('div.machine button.fast-forward').disabled =
      (@state == 'OFF' || @next_line == null)

    if @state == 'OFF'
      $one('div.machine button.power').classList.remove 'active'
    else
      $one('div.machine button.power').classList.add 'active'

    if @state != 'RUNNING'
      $one('div.machine button.fast-forward').classList.remove 'active'
    else
      $one('div.machine button.fast-forward').classList.add 'active'

  clickPower: ->
    if @state == 'OFF'
      @state = 'WAITING'
      @next_line = 1
      $one('div.machine .before-cursor').textContent = ''
    else
      @state = 'OFF'
      @next_line = null
    @refreshDisplays()
    @_showNextLine (->)

  _executeNextLineGettingOutput: ->
    if @next_line == 1
      @next_line = 2
      return "1\n"
    else if @next_line == 2
      @next_line = 3
      return "2\n"
    else if @next_line == 3
      @state = 'WAITING'
      @next_line = null
      return "3\n"

  clickRun: ->
    return unless @state == 'WAITING'
    @state = 'RUNNING'
    @_continueRun()

  _continueRun: ->
    @_boldNextLine =>
      @_executeNextLine =>
        @_unboldNextLine =>
          @_showNextLine =>
            @refreshDisplays()
            if @next_line != null
              @_continueRun()

  _boldNextLine: (callback) ->
    from = { line: @next_line - 1, ch: 0 }
    to   = { line: @next_line, ch: 0 }
    @being_bolded_marker =
      @code_mirror.markText from, to, className: 'running'
    @setTimeout callback, MILLIS_FOR_BOLD

  _executeNextLine: (callback) ->
    outputNextLetter = (rest) ->
      nextLetter = rest[0]
      rest = rest[1..-1]
      $one('div.machine .before-cursor').textContent += nextLetter
      if rest == ''
        @setTimeout callback, MILLIS_FOR_OUTPUT
      else
        @setTimeout (-> outputNextLetter rest), MILLIS_FOR_OUTPUT_LETTER
    output = @_executeNextLineGettingOutput()
    outputNextLetter output

  _unboldNextLine: (callback) ->
    @being_bolded_marker.clear()
    @being_bolded_marker = null
    @setTimeout callback, MILLIS_FOR_UNBOLD

  _showNextLine: (callback) ->
    if @next_line
      y = @code_mirror.heightAtLine(@next_line - 1)
      $one('div.machine .next-line .pointer').style.top = "#{y}px"
    $one('div.machine .next-line .pointer').style.display =
      (if @next_line then 'block' else 'none')

    if @line_num_to_unhighlight != null
      @code_mirror.removeLineClass @line_num_to_unhighlight - 1,
        'text', 'current-line'
    if @next_line != null
      @code_mirror.addLineClass @next_line - 1, 'text', 'current-line'
      @line_num_to_unhighlight = @next_line

    @setTimeout callback, MILLIS_FOR_MOVED_ARROW

setupMachine = (code_mirror) ->
  setTimeout = (f, seconds) -> window.setTimeout(f, seconds)
  machine = new Machine(40, setTimeout, code_mirror)
  for button in $all('div.machine button.power')
    button.addEventListener 'click', ->
      machine.clickPower()
  for button in $all('div.machine button.fast-forward')
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
