source 'http://rubygems.org'

gem 'sinatra', '~> 1.2', :require => 'sinatra/base'
gem 'dragonfly', '~> 0.9'
gem 'magickly', '~> 1.2'

gem 'addressable', '~> 2.2', :require => 'addressable/uri'
gem 'haml', '~> 3.0'

gem 'face', '0.0.4'
gem 'imagesize', '~> 0.1', :require => 'image_size'

group :development do
  gem 'jeweler', '~> 1.6'
end

group :development, :test do
  gem "guard"
  gem "guard-bundler"
  gem "guard-rack"

  gem 'rack-test', :require => 'rack/test'
  gem 'rspec', '~> 2.5'
  gem 'webmock', '~> 1.8', :require => 'webmock/rspec'
  gem 'vcr', '~> 2.0'
  
  gem 'ruby-debug19', :require => 'ruby-debug', :platforms => :ruby_19
  # dont use unreleased 0.5.13 gem
  gem 'linecache19', '0.5.12', :platforms => :ruby_19
  gem 'ruby-debug', :platforms => :ruby_18
end

group :production do
  gem 'newrelic_rpm', :require => false
end
