require 'rubygems'
require 'bundler/setup'
require 'sinatra'

set :environment, :test
set :run, false
set :raise_errors, true

run Sinatra::Application
