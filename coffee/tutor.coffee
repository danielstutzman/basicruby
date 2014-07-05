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
  if trace['test_status']
    html += "<div class='test-status #{trace['test_status'].toLowerCase()}'>"
    html += trace['test_status'] + "</div>"
  html += "</li>"

  html += "</ul>"
  html += "<div id='trace_render_div#{i}'></div>"
  html


represent_value_simple = (value) ->
  klass = value.$class().$to_s()
  switch klass
    when 'NilClass'   then null
    when 'Numeric'    then value.valueOf()
    when 'String'     then value.valueOf()
    when 'TrueClass'  then true
    when 'FalseClass' then false
    when 'Array'      then ['REF', value.$object_id()]
    when 'Hash'       then ['REF', value.$object_id()]
    when 'Proc'       then ['REF', value.$object_id()]
    else klass

represent_value = (value, heap) ->
  klass = value.$class().$to_s()
  switch klass
    when 'NilClass'   then null
    when 'Numeric'    then value.valueOf()
    when 'String'     then value.valueOf()
    when 'TrueClass'  then true
    when 'FalseClass' then false
    when 'Array'
      on_heap = ['LIST'].concat _.map value, (element) ->
        represent_value element, heap
      heap[value.$object_id()] = on_heap
      ['REF', value.$object_id()]
    when 'Hash'
      on_heap = ['DICT'].concat _.map value.keys, (key) ->
        [represent_value(key, heap), represent_value(value.map[key], heap)]
      heap[value.$object_id()] = on_heap
      ['REF', value.$object_id()]
    when 'Proc'
      on_heap = ['FUNCTION', "line # unknown", null]
      heap[value.$object_id()] = on_heap
      ['REF', value.$object_id()]
    else klass

new_trace_entry = (interpreter, line_num) ->
  varsStack = interpreter.visibleState().varsStack

  # prepare heap variable
  heap = {}
  for vars in varsStack
    for pair in _.pairs(_.omit(vars.map, '__method_name'))
      if pair[1].length == 2
        represent_value pair[1][1], heap

  trace_entry =
    ordered_globals:[]
    stdout: _.map(interpreter.getStdoutAndStderr(), (pair) -> pair[1]).join('')
    func_name:"main"
    stack_to_render:[]
    globals:{}
    heap:heap
    line:line_num
    event:"step_line"
  for vars, i in varsStack
    locals = {}
    keys = []
    for key in vars.keys
      tuple = vars.map[key.$to_s()]
      if tuple.length == 2 && key.$to_s().indexOf('__') != 0
        keys.push key.$to_s()
        locals[key.$to_s()] = represent_value_simple(tuple[1])
    method_name = vars.map['__method_name'][1].$to_s()
    method_name_for_hash = method_name.replace(/['<> ]/g, '')
    trace_entry.stack_to_render.push
      frame_id: i
      encoded_locals: locals
      is_highlighted: false
      is_parent: i < varsStack.length - 1
      func_name: method_name
      is_zombie: false
      parent_frame_id_list: []
      unique_hash: "#{i}_#{method_name_for_hash}"
      ordered_varnames: keys
  trace_entry

traces = []

compile_to_traces = (code) ->
  traces.splice 0 # clear out traces
  for case_ in (exercise['cases'] || [{}])
    given_vars = case_['given'] || {}
    given_vars_statements = _.map _.keys(given_vars), (var_name) ->
      "#{var_name} = #{given_vars[var_name].$inspect()}\n"
    num_givens = _.keys(given_vars).length
    code_with_givens = given_vars_statements.join('') + code
    bytecodes = AstToBytecodeCompiler.compile [['YourCode', code_with_givens]]
    if bytecodes
      bytecodes = _.compact _.map bytecodes, (bytecode) ->
        if bytecode[0] == 'position'
          if bytecode[2] > num_givens
            [bytecode[0], bytecode[1], bytecode[2] - num_givens, bytecode[3]]
          else
            null # will be removed by _.compact
        else if bytecode[0] == 'token'
          if bytecode[1] > num_givens
            [bytecode[0], bytecode[1] - num_givens, bytecode[2]]
          else
            null # will be removed by _.compact
        else
          bytecode
      trace = execute_to_trace bytecodes, given_vars
      test_status = determine_test_status trace, case_
      traces.push { code: code, returned: null, trace, test_status }
  null

execute_to_trace = (bytecodes, given_vars) ->
  trace = []
  spool = new BytecodeSpool bytecodes
  interpreter = new BytecodeInterpreter()
  spool.queueRunUntil 'DONE'
  i = 0
  line_num = 1
  ended_abnormally = false
  until spool.isDone()
    i += 1
    if i > 10000
      interpreter.undefineMethods()
      spool.terminateEarly()
      ended_abnormally = true
      trace.push
        event: 'instruction_limit_reached'
        exception_msg: "(stopped after #{i} steps to prevent infinite loop)"
      break
    bytecode = spool.getNextBytecode()
    try
      if bytecode[0] == 'position' && bytecode[1] == 'YourCode'
        line_num = bytecode[2]
      if bytecode[0] == 'position' && bytecode[1] == 'YourCode' ||
         bytecode[0] == 'return'
        trace.push new_trace_entry(interpreter, line_num)
      spoolCommand = interpreter.interpret bytecode
      spool.doCommand.apply spool, spoolCommand
    catch e
      if e.name == 'ProgramTerminated'
        interpreter.undefineMethods()
        spool.terminateEarly()
        ended_abnormally = true
        trace.push new_trace_entry(interpreter, line_num)
        _.last(trace).event = 'uncaught_exception'
        _.last(trace).exception_msg = e.message
      else
        throw e
  unless ended_abnormally
    trace.push new_trace_entry(interpreter, line_num)
  trace

determine_test_status = (trace, case_) ->
  last = _.last(trace) || {}
  chomp = (string) ->
    string.replace /\s+$/, ''

  if last['exception_msg']
    'ERROR'
  else if _.keys(case_).length == 0
    null # cases don't apply to this exercise
  else if expected_stdout = case_['expected_stdout']
    if chomp(last['stdout'] || '') == chomp(expected_stdout)
      'PASSED'
    else
      'FAILED'

render_traces = ->
  if typeof traces isnt 'undefined'
    html = ''
    for trace, i in traces
      html += """
        <a class='case-tab-link' href='#'>
          <div class='tab case-tab' data-case-num='#{i}'>
            <h2>
              #{if exercise && exercise['cases'] then "Case #{i}" else 'Debug'}
              #{if trace['test_status']
                "<div class='test-status #{trace['test_status'].toLowerCase()}'>
                  #{trace['test_status']}
                </div>"
              else ''}
            </h2>
          </div>
        </a>
      """
    $('.traces-tabs').html html

    html = ''
    # if no cases provided, assume just one case with no variables pre-assigned
    cases = (exercise && exercise['cases']) || [{}]
    for trace, i in traces
      html += "<div class='case-content' data-case-num='#{i}'>"
      if exercise && exercise['description']
        html += exercise['description'].replace /`([^`]*)`/, "<code>$1</code>"
      if cases[i]
        html += html_for_case cases[i], i, trace
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

post_to_database = (button, code) ->
  auth_token = $('meta[name=csrf-token]').attr('content')
  promise = $.post window.location.pathname,
    button: button
    user_code_textarea: code
    authenticity_token: auth_token
  promise.fail (data) ->
    window.alert "Failed #{button}: #{data.status} #{data.statusText}"
  promise

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

  compile_to_traces codeMirror.getValue()
  render_traces()

  $('#restore-button').click (e) ->
    if confirm('Are you sure you want to discard your current code?')
      promise = post_to_database 'restore', null
      promise.done ->
        window.location.reload()
    e.preventDefault()

  $('#save-button').click (e) ->
    compile_to_traces codeMirror.getValue()
    render_traces()
    post_to_database 'save', codeMirror.getValue()
    e.preventDefault()
