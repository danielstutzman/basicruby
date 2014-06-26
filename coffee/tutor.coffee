# Overwrite assert so we get a stack trace not just a message
window.assert = (cond) ->
  if not cond
    throw new Error('Assertion Failure')

changePythonToRuby = ->
  
  # Change None to nil
  $('span.nullObj').html 'nil'
  
  # Change True to true and False to false
  $('span.boolObj').css 'text-transform', 'lowercase'
  
  # Change dict to Hash and list to Array
  $('div.typeLabel').each (i) ->
    label = this
    labelNode = label.childNodes[0]
    if labelNode
      labelNode.nodeValue = switch labelNode.nodeValue
        when 'dict' then 'Hash'
        when 'list' then 'Array'
        when 'function' then 'Proc'
        else labelNode.nodeValue
  
  # "a\n'b" should be rendered as a(next line)'b not "a \'b"
  $('span.stringObj').each (i) ->
    s = this
    sNode = s.childNodes[0]
    if sNode
      without_dquotes = sNode.nodeValue.replace(/^"([\s\S]*)"$/, '$1')
      sNode.nodeValue = without_dquotes.replace(/\\'/g, '\'')

  $('#pyCodeOutput').click ->
    $('#trace_render_div').hide()
    $('#user_code_div').show()

$(document).ready ->
  
  textarea = $('#user_code_textarea')[0]
  CodeMirror.fromTextArea(textarea,
    mode: 'ruby'
    lineNumbers: true
    tabSize: 2
    indentUnit: 2
    extraKeys: # convert tab into two spaces:
      Tab: (cm) ->
        cm.replaceSelection '  ', 'end'
    autofocus: true
  )

  if typeof traces_json isnt 'undefined'
    traces = $.parseJSON(traces_json)
    setupVisualizer = (i) ->
      visualizer = null
      redrawAllVisualizerArrows = ->
        # Take advantage of the callback to convert some Python things to Ruby
        changePythonToRuby()
        visualizer.redrawConnectors() if visualizer

      visualizer = new ExecutionVisualizer("trace_render_div#{i}", traces[i],
        embeddedMode: false
        heightChangeCallback: redrawAllVisualizerArrows
        editCodeBaseURL: null
      )

    i = 0
    while i < traces.length
      setupVisualizer i
      i++

    # Use id selectors instead of # because there are multiple buttons
    # with the same id unfortunately.
    $("button[id=jmpFirstInstr]").click (event) -> changePythonToRuby()
    $("button[id=jmpStepBack]").click (event)   -> changePythonToRuby()
    $("button[id=jmpStepFwd]").click (event)    -> changePythonToRuby()
    $("button[id=jmpLastInstr]").click (event)  -> changePythonToRuby()

  $('#edit-tab').addClass 'selected'
  $('.case-content').hide()
  $('#edit-tab-link').click (event) ->
    if event.target.nodeName is 'BUTTON'
      true
    else
      $('.case-content').hide()
      $('#edit-content').show()
      $('.case-tab').removeClass 'selected'
      $('#edit-tab').addClass 'selected'
      event.preventDefault()
      false

  $('.case-tab-link').click (event) ->
    case_tab = $(event.target).closest('.case-tab')
    case_num = case_tab.attr('data-case-num')
    $('#edit-content').hide()
    $('.case-content').hide()
    $(".case-content[data-case-num='#{case_num}']").show()
    $('#edit-tab').removeClass 'selected'
    $('.case-tab').removeClass 'selected'
    case_tab.addClass 'selected'
    event.preventDefault()
    false

  $('#restore-button').click (event) ->
    confirm('Are you sure you want to discard your current code?')
