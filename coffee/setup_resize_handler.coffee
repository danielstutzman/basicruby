$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

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

module.exports =
  setupResizeHandler: setupResizeHandler
