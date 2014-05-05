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

# states: OFF, WAITING, RUNNING
class Machine
  MILLIS_FOR_BOLD = 300
  MILLIS_FOR_OUTPUT = 300
  MILLIS_FOR_OUTPUT_LETTER = 100
  MILLIS_FOR_UNBOLD = 500
  MILLIS_FOR_SCROLLED_INSTRUCTIONS = 500
  MILLIS_FOR_SCROLLED_INSTRUCTIONS_TENTH = 5

  constructor: (line_height, setTimeout, code_mirror) ->
    @program = null
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
    $one('div.machine button.step').disabled =
      (@state == 'OFF' || @next_line == null)

    if @state == 'OFF'
      $one('div.machine button.power').classList.remove 'active'
    else
      $one('div.machine button.power').classList.add 'active'

    if @state != 'RUNNING'
      $one('div.machine button.fast-forward').classList.remove 'active'
    else
      $one('div.machine button.fast-forward').classList.add 'active'

    scrollConsole = ->
      $one('div.machine .console').scrollTop =
        $one('div.machine .console').scrollHeight
    @setTimeout scrollConsole, 1 # timeout to avoid weird layout bug

  _codeWithLineNums: ->
    lines = @code_mirror.getValue().split("\n")
    new_lines = ["<br>\n"] # blank line at beginning
    line_num = 1
    for line in lines
      new_lines.push "<div class='num _#{line_num}'>#{line_num}</div> " +
        "<div class='code _#{line_num}'>#{escapeHTML(line)}</div>"
      line_num += 1

    # blank lines at end, so we can scroll if program is short and has blank
    # lines at the top
    new_lines.join("\n") + "<br clear='all'><br>"

  clickPower: ->
    if @state == 'OFF'
      @state = 'WAITING'
      @program = compile(@code_mirror.getValue())
      @next_line = @program.map['start']
      @next_line = null if @next_line == 'finish'
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
    next_line = @program.map[@next_line].map.next
    output    = @program.map[@next_line].map.output
    if next_line == 'finish'
      @state = 'WAITING'
      @next_line = null
    else
      @next_line = next_line
    return output

  clickRun: ->
    return unless @state == 'WAITING'
    @state = 'RUNNING'
    @_continueRun()

  clickStep: ->
    return unless @state == 'WAITING'
    @_doStep (->)

  _doStep: (callback) ->
    @_boldNextLine =>
      @_executeNextLine =>
        @_unboldNextLine =>
          @_showNextLine =>
            @refreshDisplays()
            callback()

  _continueRun: ->
    @_doStep =>
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
      if nextLetter == "\n"
        $one('div.machine .console').scrollTop =
          $one('div.machine .console').scrollHeight
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
  for button in $all('div.machine button.step')
    button.addEventListener 'click', ->
      machine.clickStep()
  for button in $all('div.machine button.fast-forward')
    button.addEventListener 'click', ->
      machine.clickRun()
  machine.refreshDisplays()

module.exports =
  setupMachine: setupMachine
