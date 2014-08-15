$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

heightOfDiv = (div) ->
  if div
    div.getBoundingClientRect().bottom - div.getBoundingClientRect().top
  else
    0

resizeDivs = (w, h) ->
  title_h      = heightOfDiv $one 'div.title'
  banner_h     = heightOfDiv $one 'div.banner'

  height_under_banner = Math.floor(h - title_h - banner_h)
  if height_under_banner < 400
    height_under_banner = 400

  for debugger_ in $all('.debugger')
    debugger_.style.height = "#{h * 0.90}px"
  for col in $all('.col-1-of-2, .col-2-of-2')
    col.style.height = "#{height_under_banner}px"

setupResizeHandler = (code_mirrors) ->
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
      for code_mirror in code_mirrors
        code_mirror.refresh()
  window.setInterval resizeIfChanged, 500
  resizeIfChanged()
  resizeIfChanged()
  forceResize = ->
    w = window.innerWidth
    h = window.innerHeight
    resizeDivs w, h
    for code_mirror in code_mirrors
      code_mirror.refresh()

module.exports =
  setupResizeHandler: setupResizeHandler
