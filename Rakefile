# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

BasicRuby::Application.load_tasks

task :docker => %w[
  docker/rails/Dockerfile
  docker/rails/preserve-env.conf
  docker/rails/basicruby.conf.template
] do |task|
  filenames = task.prerequisites.map { |path| path.split('/').last }
  command = ["rm -f #{filenames.join(' ')}"]
  task.prerequisites.each do |path|
    command.push "ln -s #{path}"
  end
  command.push 'docker build .'
  command.push "rm -f #{filenames.join(' ')}"
  sh command.join(";\n")
end
