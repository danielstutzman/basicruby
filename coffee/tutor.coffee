AstToBytecodeCompiler = require './AstToBytecodeCompiler.coffee'
BytecodeInterpreter   = require './BytecodeInterpreter.coffee'
BytecodeSpool         = require './BytecodeSpool.coffee'

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

html_for_case = (_case, i, trace) ->
  html = ''
  html += "<ul>"
  html += "<li><b>Case number:</b> #{i}</li>"

  if _case['given']
    html += "<li><b>Given:</b> "
    givens = _.map _.pairs((_case['given'] || {})), (var_and_val) ->
      "#{var_and_val[0]} = #{var_and_val[1]}"
    html += givens.join(', ') + "</li>"

  if _case['expected_return']
    html += "<li><b>Expected return:</b> #{_case['expected_return']}</li>"
    html += "<li><b>Actual return:</b> #{trace['returned']}</li>"

  else if _case['expected_stdout']
    html += "<li><b>Expected output:</b> "
    html += "<pre style='display:inline-block;vertical-align:top'>"
    html += _case['expected_stdout'].replace(/</, '&lt;')
    html += "</pre>"
    html += "</li>"
    html += "<li><b>Actual output:</b> "
    html += "<pre style='display:inline-block;vertical-align:top'>"
    html += _.last(trace['trace']) &&
      (_.last(trace['trace'])['stdout'] || '').replace(/</, '&lt;')
    html += "</pre>"
    html += "</li>"

  if _.last(trace['trace']) && _.last(trace['trace'])['exception_msg']
    html += "<li><b>Uncaught exception:</b> "
    html += "<code class='exception'>"
    html += _.last(trace['trace'])['exception_msg']
    html += "</code>"
    html += "</li>"

  html += "<li><b>Result:</b> "
  html += "</li>"
  if trace['test_status']
    html += "<div class='test-status #{trace['test_status'].toLowerCase()}'>"
    html += trace['test_status'] + "</div>"
  html += "</li>"

  html += "</ul>"
  html += "<div id='trace_render_div#{i}'></div>"
  html

new_trace_entry = (interpreter, line_num) ->
  locals = {}
  map = _.omit(interpreter.visibleState().varsStack[0].map, '__method_name')
  for pair in _.pairs(map)
    if pair[1].length == 2
      locals[pair[0]] = pair[1][1].valueOf()
  trace_entry =
    ordered_globals:[]
    stdout: _.map(interpreter.getStdoutAndStderr(), (pair) -> pair[1]).join()
    func_name:"main"
    stack_to_render:[]
    globals:{}
    heap:{}
    line:line_num
    event:"step_line"
  trace_entry.stack_to_render.push
    frame_id:0
    encoded_locals: locals
    is_highlighted:false
    is_parent:false
    func_name:"<main>"
    is_zombie:false
    parent_frame_id_list:[]
    unique_hash:"0_"
    ordered_varnames: _.map _.without(interpreter.visibleState().varsStack[0].keys, '__method_name'), (key) -> key.$to_s()
  trace_entry

save = (code) ->
  trace = []

  bytecodes = AstToBytecodeCompiler.compile [['YourCode', code]]
  if bytecodes
    spool = new BytecodeSpool bytecodes
    interpreter = new BytecodeInterpreter()
    spool.queueRunUntil 'DONE'
    i = 0
    until spool.isDone()
      i += 1
      if i > 10000
        throw "Interpreter seems to be stuck in a loop"
      bytecode = spool.getNextBytecode()
      try
        if bytecode[0] == 'position' && bytecode[1] == 'YourCode'
          line_num = bytecode[2]
          trace.push new_trace_entry(interpreter, line_num)
        spoolCommand = interpreter.interpret bytecode
        spool.doCommand.apply spool, spoolCommand
      catch e
        if e.name == 'ProgramTerminated'
          interpreter.undefineMethods()
          spool.terminateEarly()
        else
          throw e
    trace.push new_trace_entry(interpreter, line_num)
    trace

render_traces = ->
  console.log traces

  if typeof traces isnt 'undefined'
    html = ''
    for trace, i in traces
      html += """
        <a class='case-tab-link' href='#'>
          <div class='tab case-tab' data-case-num='#{i}'>
            <h2>
              #{if @exercise && @exercise['cases'] then "Case #{i}" else 'Debug'}
              #{if trace['test_status']
                "<div class='test-status #{trace['test_status'].toLowerCase()}'
                  #{trace['test_status']}
                </div>"
              else ''}
            </h2>
          </div>
        </a>
      """
    $('.traces-tabs').html html

    html = ''
    for trace, i in traces
      html += "<div class='case-content' data-case-num='#{i}'>"
      if exercise && exercise['description']
        html += exercise['description'].replace /`([^`]*)`/, (match) ->
          "<code>#{match[1]}</code>"
      if exercise && exercise['cases'] && exercise['cases'][i]
        html += html_for_case exercise['cases'][i], i, trace
      html += "</div>"
    $('.case-contents').html html

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

$(document).ready ->

  textarea = $('#user_code_textarea')[0]
  codeMirror = CodeMirror.fromTextArea(textarea,
    mode: 'ruby'
    lineNumbers: true
    tabSize: 2
    indentUnit: 2
    extraKeys: # convert tab into two spaces:
      Tab: (cm) ->
        cm.replaceSelection '  ', 'end'
    autofocus: true
  )

  render_traces()

  $('#restore-button').click (event) ->
    confirm('Are you sure you want to discard your current code?')

  $('#save-button').click ->
    code = codeMirror.getValue()
    trace = save(code)
    traces.splice 0
    traces.push { code: code, returned: null, trace: trace }
    render_traces()
