# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

BasicRuby::Application.load_tasks

def create_with_sh(command, path)
  begin
    sh "#{command} > #{path}"
  rescue
    sh "rm -f #{path}"
    raise
  end
end

if defined?(before)
  before 'assets:precompile' do
    system 'npm install --production'
    Rake::Task['app/assets/javascripts/browserified-prod.js'].invoke
    Rake::Task['app/assets/javascripts/ruby_to_pos_to_result.js'].invoke
  end
end

file 'app/assets/javascripts/browserified-prod.js' =>
    Dir.glob('coffee/*.coffee') do |task|
  dash_r_paths = task.prerequisites.map { |path|
    ['-r', "./#{path}"]
  }.flatten.join(' ')
  command = %W[
    node_modules/.bin/browserify
      -t coffeeify
      -t uglifyify
      --insert-global-vars ''
      -d
      #{dash_r_paths}
  | node
      node_modules/exorcist/bin/exorcist.js
      public/browserified.js.map
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/ruby_to_pos_to_result.js' =>
    'lib/ruby_to_pos_to_result.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- ruby_to_pos_to_result
  ].join(' ')
  create_with_sh command, task.name
end
