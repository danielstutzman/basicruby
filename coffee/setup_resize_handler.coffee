$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

heightOfDiv = (div) ->
  if div
    div.getBoundingClientRect().bottom - div.getBoundingClientRect().top
  else
    0

resizeDivs = (w, h) ->
  title_h      = heightOfDiv $one 'div.title-bar'
  assignment_h = heightOfDiv $one 'div.assignment-above'
  solution_h   = heightOfDiv $one '#solution-section'
  actions_h    = heightOfDiv $one '.actions'
  fudge = 40

  height_total = Math.floor(h -
    title_h - assignment_h - solution_h - actions_h - fudge)
  if height_total < 400
    height_total = 400

  stretch = $one('.section.stretch-section .consistent-height')
  if stretch
    stretch.style.height = "#{height_total}px"
    resizeConsoleToFitHeight stretch

resizeConsoleToFitHeight = (div) ->
  height_total = heightOfDiv div
  buttons_h = heightOfDiv div.querySelector('.buttons')
  instructions_h = heightOfDiv div.querySelector('.instructions')
  _console = div.querySelector('.debugger .console')
  vars_h = heightOfDiv div.querySelector('.variables')
  fudge = 40
  if _console
    height_console = height_total - buttons_h - instructions_h - vars_h - fudge
    _console.style.height = "#{height_console}px"

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
      isChanging = false
      resizeDivs w, h
      code_mirror.refresh()
  window.setInterval resizeIfChanged, 500
  resizeIfChanged()
  resizeIfChanged()
  forceResize = ->
    w = window.innerWidth
    h = window.innerHeight
    resizeDivs w, h
    code_mirror.refresh()

module.exports =
  setupResizeHandler: setupResizeHandler
  resizeConsoleToFitHeight: resizeConsoleToFitHeight
