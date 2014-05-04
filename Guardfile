guard :shell do
  watch /.*.coffee$/ do
    `rake app/assets/javascripts/browserified-dev.js`
  end
  watch /lib\/ruby_to_pos_to_result.rb$/ do
    `rake app/assets/javascripts/ruby_to_pos_to_result.js`
  end
end
