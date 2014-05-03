$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

MAP =
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'
  '"': '&quot;'
  "'": '&#39;'

escapeHTML = (s, forAttribute) ->
  regex = if forAttribute then /[&<>'"]/g else /[&<>]/g
  s.replace regex, (c) -> MAP[c]

resizeDivs = (w, h) ->
  assignment_y2 = $one('div.assignment-above').getBoundingClientRect().bottom
  actions_div = $one('.actions')
  if actions_div
    actions_h = actions_div.getBoundingClientRect().bottom -
                actions_div.getBoundingClientRect().top
  else
    actions_h = 0
  console_y = $one('div.machine .console').getBoundingClientRect().top

  height_total = Math.floor(h - assignment_y2 - actions_h)
  height_above_console = Math.ceil(console_y - assignment_y2)
  height_console = height_total - height_above_console

  for div in $all('.code-editor, .CodeMirror')
    div.style.height = "#{height_total}px"
  for div in $all('div.machine .console')
    div.style.height = "#{height_console}px"
  for div in $all('div.machine')
    div.style.height = "#{height_total}px"

setupResizeHandler = (code_mirror) ->
  oldW = 0
  oldH = 0
  isChanging = false
  resizeIfChanged = ->
    # if this doesn't work, can try <svg id='svg'
    #   xmlns='http://www.w3.org/2000/svg' version='1.1'
    #   style='display:none'></svg> and
    #   document.getElementById('svg').currentScale
    w = window.innerWidth
    h = window.innerHeight
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
  MILLIS_FOR_SCROLLED_INSTRUCTIONS = 500
  MILLIS_FOR_SCROLLED_INSTRUCTIONS_TENTH = 5

  constructor: (line_height, setTimeout, code_mirror) ->
    @state = 'OFF'
    @next_line = null
    @line_height = line_height
    @setTimeout = setTimeout
    @code_mirror = code_mirror
    @old_bolded_line = null

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

  _codeWithLineNums: ->
    lines = $one('textarea.code-editor').textContent.split("\n")
    new_lines = ["<br>\n"] # blank line at beginning
    line_num = 1
    for line in lines
      new_lines.push "<div class='num _#{line_num}'>#{line_num}</div> " +
        "<div class='code _#{line_num}'>#{escapeHTML(line)}</div>"
      line_num += 1
    new_lines.join("\n") + "<br>\n" # blank line at end

  clickPower: ->
    if @state == 'OFF'
      @state = 'WAITING'
      @next_line = 1
      $one('div.machine .before-cursor').textContent = ''
      $one('div.machine .instructions .content').innerHTML =
        @_codeWithLineNums()
    else
      @state = 'OFF'
      @next_line = null
      $one('div.machine .instructions .content').innerHTML = ''
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
    line = $one("div.machine .instructions .content .code._#{@next_line}")
    line.classList.add 'bold'
    @old_bolded_line = line
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
    if @old_bolded_line
      @old_bolded_line.classList.remove 'bold'
      @old_bolded_line = null
    @setTimeout callback, MILLIS_FOR_UNBOLD

  _showNextLine: (callback) ->
    $pointer = $one('.machine .instructions .pointer')
    $content = $one('.machine .instructions .content')
    if @next_line
      $pointer.style.display = 'block'
      $content.style.display = 'block'
      element_1 = $one("div.machine .instructions .content .num._1")
      element_n = $one("div.machine .instructions .content .num._#{@next_line}")
      old_scroll_top = $content.scrollTop
      new_scroll_top = element_n.getBoundingClientRect().top -
                       element_1.getBoundingClientRect().top
      animateScrollTop = (progress) ->
        progress = 1.0 if progress > 1.0
        $content.scrollTop = (1.0 - progress) * old_scroll_top +
          progress * new_scroll_top
        if progress < 1.0
          @setTimeout (=> animateScrollTop (progress + 0.1)),
            MILLIS_FOR_SCROLLED_INSTRUCTIONS_TENTH
        else
          @setTimeout callback, MILLIS_FOR_SCROLLED_INSTRUCTIONS
      animateScrollTop 0.1
    else
      $pointer.style.display = 'none'
      $content.style.display = 'none'
      @setTimeout callback, MILLIS_FOR_SCROLLED_INSTRUCTIONS

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
    code_mirror = CodeMirror.fromTextArea($one('.code-editor'), options)
    setupMachine code_mirror
    setupResizeHandler code_mirror
