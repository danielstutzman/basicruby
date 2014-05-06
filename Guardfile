guard :shell do
  watch /.*.coffee$/ do
    `rake app/assets/javascripts/browserified.js`
  end
  watch /lib\/ruby_to_pos_to_result.rb$/ do
    `rake app/assets/javascripts/ruby_to_pos_to_result.js`
  end
  watch /lib\/bytecode_compiler.rb$/ do
    `rake app/assets/javascripts/bytecode_compiler.js`
  end
  watch /lib\/bytecode_interpreter.rb$/ do
    `rake app/assets/javascripts/bytecode_interpreter.js`
  end
end
