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
    Rake::Task['js'].invoke
  end
end

file 'app/assets/javascripts/browserified.js' =>
    Dir.glob('coffee/*.coffee') do |task|
  dash_r_paths = task.prerequisites.map { |path|
    ['-r', "./#{path}"]
  }.flatten.join(' ')
  command = %W[
    node_modules/.bin/browserify
      -t coffeeify
      #{ENV['RAILS_ENV'] == 'assets' ? '-t uglifyify' : ''}
      --insert-global-vars ''
      -d
      #{dash_r_paths}
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

file 'app/assets/javascripts/bytecode_compiler.js' =>
    'lib/bytecode_compiler.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- bytecode_compiler
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/bytecode_interpreter.js' =>
    'lib/bytecode_interpreter.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- bytecode_interpreter
  ].join(' ')
  create_with_sh command, task.name
end

task :js => %w[
  app/assets/javascripts/browserified.js
  app/assets/javascripts/ruby_to_pos_to_result.js
  app/assets/javascripts/bytecode_compiler.js
  app/assets/javascripts/bytecode_interpreter.js
]
