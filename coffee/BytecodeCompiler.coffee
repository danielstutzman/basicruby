compile_ruby_code_to_hash = (ruby_code) ->
  Opal.BytecodeCompiler.$new().$compile_ruby_program_to_hash ruby_code

module.exports =
  compile_ruby_code_to_hash: compile_ruby_code_to_hash
