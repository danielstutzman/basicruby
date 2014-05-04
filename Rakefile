# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

BasicRuby::Application.load_tasks

before 'assets:precompile' do
  system 'ls'
end
