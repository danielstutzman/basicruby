$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

resizeDivs = (w, h) ->
  assignment_y2 = $one('div.assignment-above').getBoundingClientRect().bottom
  height_total = Math.floor(h - assignment_y2)

  $console = $one('.section.stretch-section div.debugger .console')
  if $console
    console_y = $console.getBoundingClientRect().top
    height_above_console = Math.ceil(console_y - assignment_y2)
    height_console = height_total - height_above_console - 5
  else
    height_console = null

  if $one('.consistent-height')
    $one('.consistent-height').style.height = "#{height_total}px"
  for div in $all('.section.stretch-section div.debugger .console')
    div.style.height = "#{height_console}px"

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
