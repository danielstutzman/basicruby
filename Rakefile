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

file 'app/assets/javascripts/ast_to_bytecode_compiler.js' =>
    'lib/ast_to_bytecode_compiler.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- ast_to_bytecode_compiler
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/bytecode_interpreter.js' =>
    %w[lib/bytecode_interpreter.rb] do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- bytecode_interpreter
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/lexer.js' => 'lib/lexer.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- lexer
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/bytecode_spool.js' =>
    'lib/bytecode_spool.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- bytecode_spool
  ].join(' ')
  create_with_sh command, task.name
end

task :js => %w[
  app/assets/javascripts/ast_to_bytecode_compiler.js
  app/assets/javascripts/browserified.js
  app/assets/javascripts/bytecode_interpreter.js
  app/assets/javascripts/bytecode_spool.js
  app/assets/javascripts/lexer.js
]
