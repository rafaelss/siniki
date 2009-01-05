#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'
require 'sinatra'
require 'unicode'
require 'rdiscount'
require 'activesupport'
require 'models'
require 'helpers'
require 'monkeypatches'

enable :sessions

before do
  unless request.env['PATH_INFO'] == '/setup'
    @header = Page.header.html_body
    @menu = Page.menu.html_body
  end
end

error do
  "Sorry there was a error - #{request.env['sinatra.error']}"
end

get '/setup' do
  if File.exists?("./siniki.db")
    throw :halt, "Wiki is up and running, setup could not be executed"
  end

  DataMapper.auto_migrate!

  page = Page.new
  page.attributes = {:title => 'Welcome'}
  page.save

  page = Page.new
  page.attributes = {:title => 'Menu', :body => '[Edit menu](/menu/edit)'}
  page.save

  page = Page.new
  page.attributes = {:title => 'Header', :body => '[Edit header](/header/edit)'}
  page.save

  # TODO change admin password
  user = User.new
  user.attributes = {:username => 'admin', :password => 'aaa123' }
  user.save

  "<p>siniki is ready to run!</p><a href='/'>Go to home</a>"
end

post '/save' do
  if params[:title].nil?
    params[:title] = params[:permalink].titleize
  end

  page_id = params.delete('id')

  page = Page.new
  page.attributes = params

  if page_id.to_i.nonzero?
    page.page = Page.get(page_id)
  end

  if page.save
    redirect "/#{page.permalink}"
  else
    redirect '/edit'
  end
end

get '/new' do
  require_login

  haml :new
end

get '/login' do
  haml :login
end

post '/login' do
  user = User.login(params[:username], params[:password])
  if user
    session[:username] = user.username
    redirect session.delete(:redirect_back_to) || '/'
  else
    haml :login
  end
end

get '/logout' do
  session.delete(:username)
  redirect '/welcome'
end

get '/:permalink' do
  @page = Page.current(params[:permalink])
  if @page
    haml :page
  else
    redirect "/#{params[:permalink]}/new"
  end
end

get '/:permalink/new' do
  require_login

  @permalink = params[:permalink]
  haml :new
end

get '/:permalink/edit' do
  require_login

  @page = Page.current(params[:permalink])
  haml :edit
end

get '/:permalink/history' do
  @pages = Page.all_versions(params[:permalink])
  haml :history
end

get '/:permalink/version/:id' do
  @page = Page.get(params[:id])
  haml :page
end

get '/' do
  redirect '/welcome'
end
