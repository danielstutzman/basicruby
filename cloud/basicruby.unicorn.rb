APP_ROOT  = ENV["RAILS_ROOT"]
RAILS_ENV = ENV["RAILS_ENV"]

pid         "/home/deployer/basicruby/shared/tmp/unicorn.pid"
listen      "/home/deployer/basicruby/shared/tmp/unicorn.sock"
stderr_path "/home/deployer/basicruby/shared/log/unicorn_error.log"

working_directory "#{APP_ROOT}"
worker_processes 1
