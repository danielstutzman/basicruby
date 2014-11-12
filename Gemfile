source 'https://rubygems.org'
ruby '2.0.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.3'

# Use pg as the database for Active Record
gem 'pg'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

#group :doc do
#  # bundle exec rake doc:rails generates the API under doc/api.
#  gem 'sdoc', require: false
#end

# Use unicorn as the app server
gem 'unicorn'

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'thin'

gem 'rspec', group: :development

gem 'foreigner' # adds database-level foreign key constraints to migrations

gem 'newrelic_rpm'

gem 'brakeman', require: false

gem 'sqlite3', group: :test

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails', '~> 4.0'
end

gem 'spring', group: :development
gem 'spring-commands-rspec', group: :development

gem 'easyxdm-rails'

# Nginx 1.7.3+ will convert strong etags to weak etags so gzipping doesn't
# break, but Rails won't recognize the weak etags.
gem 'rails_weak_etags'
