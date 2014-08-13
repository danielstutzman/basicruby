guard :shell do
  watch /coffee\/.*.coffee$/ do
    `rake app/assets/javascripts/browserified.js test/browserified-coverage.js`
  end
  watch /test\/.*.coffee$/ do
    `rake test/browserified-coverage.js`
  end
  watch /lib\/ast_to_bytecode_compiler.rb$/ do
    `rake app/assets/javascripts/ast_to_bytecode_compiler.js`
  end
  watch /lib\/bytecode_interpreter.rb$/ do
    `rake app/assets/javascripts/bytecode_interpreter.js`
  end
  watch /lib\/bytecode_spool.rb$/ do
    `rake app/assets/javascripts/bytecode_spool.js`
  end
  watch /lib\/lexer.rb$/ do
    `rake app/assets/javascripts/lexer.js`
  end
end
