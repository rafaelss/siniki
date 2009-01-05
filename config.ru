require 'rubygems'
require 'sinatra'

root_dir = File.dirname(__FILE__)

Sinatra::Application.default_options.merge!(
  :views        => File.join(root_dir, 'views'),
  :app_file     => File.join(root_dir, 'siniki.rb'),
  :run          => false,
  :raise_errors => true,
  :env          => ENV['RACK_ENV'].to_sym
)

log = File.new("siniki.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

require 'siniki'
run Sinatra.application
