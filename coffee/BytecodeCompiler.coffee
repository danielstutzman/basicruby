compile_ruby_code_to_hash = (ruby_code) ->
  try
    hash = Opal.BytecodeCompiler.$new().$compile_ruby_program_to_hash ruby_code
  catch ruby_exception
    hash =
      map:
        start: '1,0'
        '1,0':
          map:
            output: "#{ruby_exception.name}: #{ruby_exception.message}"
            next: 'finish'
  hash

module.exports =
  compile_ruby_code_to_hash: compile_ruby_code_to_hash
