require 'capistrano/version'
require 'rubygems'
$:.unshift(File.dirname(__FILE__) + "/../capinatra/lib")
require 'capinatra'
load 'deploy' if respond_to?(:namespace) # cap2 differentiator

# app settings
set :app_file, "siniki.rb"
set :application, "siniki"
set :domain, "rafaelss.com"
role :app, domain
role :web, domain
role :db,  domain, :primary => true

# general settings
set :user, "rafael"
set :group, "users"
set :deploy_to, "/home/rafael/rafaelss.info/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false
default_run_options[:pty] = true

# scm settings
set :repository, "git@github.com:rafaelss/#{application}.git"
set :scm, "git"
set :branch, "master"
#set :git_enable_submodules, 1

# where the apache vhost will be generated
#set :apache_vhost_dir, "/etc/apache2/sites-enabled/"

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end
