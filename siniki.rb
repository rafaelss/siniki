#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'
require 'sinatra'
require 'unicode'
require 'rdiscount'
require 'actions'
require 'models'
require 'helpers'

enable :sessions

module Siniki
  module Markdown
    def new(html)
      super(html.gsub(/\[\[([\w |]+)\]\]/) do |m|
        title, link = $1.split('|')
        "[#{title}](/#{(link||title).to_permalink})"
      end)
    end
  end
end

RDiscount.extend(Siniki::Markdown)

class String
  def to_permalink
    str = Unicode.normalize_KD(self).gsub(/[^\x00-\x7F]/n,'')
    str = str.gsub(/[^-_\s\w]/, ' ').downcase.squeeze(' ').tr(' ', '-')
    str = str.gsub(/-+/, '-').gsub(/^-+/, '').gsub(/-+$/, '')
  end
end


before do
  @header = Page.header.html_body
  @menu = Page.menu.html_body
end

get '/setup' do
  require_login

  DataMapper.auto_migrate!

  page = Page.new
  page.attributes = {:title => 'Welcome'}
  page.save

  page = Page.new
  page.attributes = {:title => 'Menu'}
  page.save

  page = Page.new
  page.attributes = {:title => 'Header'}
  page.save

  # TODO change admin password
  user = User.new
  user.attributes = {:username => 'admin', :password => 'aaa123' }
  user.save

  "<p>siniki is ready to run!</p><a href='/'>Go to home</a>"
end

post '/save' do
  if params[:title].nil?
    params[:title] = 'Welcome'
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
    return redirect session.delete(:redirect_back_to)
  end
  haml :login
end

get '/logout' do
  session.delete(:username)
  redirect '/welcome'
end

get '/:permalink' do
  @page = Page.last_version(params[:permalink])
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

  @page = Page.last_version(params[:permalink])
  haml :edit
end

get '/' do
  redirect '/welcome'
end
