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

  for div in document.querySelectorAll('body.machine .code')
    div.style.width  = "#{width_code}px"
    div.style.height = "#{height_code}px"
  for div in document.querySelectorAll('body.machine .machine .console')
    div.style.width  = "#{width_console}px"
    div.style.height = "#{height_console}px"
  for div in document.querySelectorAll('body.machine .machine .next-line')
    div.style.height = "#{height_next_line}px"

setupResizeHandler = ->
  oldW = 0
  oldH = 0
  isChanging = false
  resizeIfChanged = ->
    # if this doesn't work, can try <svg id='svg'
    #   xmlns='http://www.w3.org/2000/svg' version='1.1'
    #   style='display:none'></svg> and
    #   document.getElementById('svg').currentScale
    w = window.innerWidth - 62
    h = window.innerHeight - 70
    if w != oldW or h != oldH
      isChanging = true
      oldW = w
      oldH = h
    else if isChanging
      resizeDivs w, h
      isChanging = false
  window.setInterval resizeIfChanged, 500
  resizeIfChanged()
  resizeIfChanged()

document.addEventListener 'DOMContentLoaded', ->
  setupResizeHandler()
