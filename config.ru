require 'rubygems'
require 'bundler'
Bundler.require

require File.join(File.dirname(__FILE__), 'lib', 'buscemi', 'app')

map '/' do
  run Buscemi::App
end

map '/magickly' do
  run Magickly::App
end
