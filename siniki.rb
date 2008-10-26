#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'dm-core'
require 'sinatra'
require 'unicode'
require 'rdiscount'

enable :sessions

DataMapper.setup(:default, 'sqlite3:siniki.db')

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

class Page
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :title, String, :nullable => false
  property :body, Text
  property :processed_body, Text
  property :permalink, String, :nullable => false
  property :created_at, DateTime
  property :updated_at, DateTime

  before :save, :set_permalink
  before :save, :process_body

  def self.welcome
    Page.first(:permalink => 'welcome')
  end

  def self.header
    Page.first(:permalink => 'header')
  end

  def self.menu
    Page.first(:permalink => 'menu')
  end

  private

  def set_permalink(context = :default)
    self.permalink = self.title.to_permalink if self.permalink.nil?
  end

  def process_body
    unless self.body.nil?
      markdown = RDiscount.new(self.body)
      self.processed_body = markdown.to_html
    end
  end
end

class User
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :username, String, :nullable => false
  property :password, String, :nullable => false

  def self.login(username, password)
    first(:username => username, :password => password)
  end
end

before do
  @header = Page.header.processed_body
  @menu = Page.menu.processed_body
end

get '/setup' do
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

  "siniki is ready to run!"
end

helpers do
  def logged_in?
    session[:username]
  end

  def require_login
    unless logged_in?
      session[:redirect_back_to] = request.env['REQUEST_URI']
      redirect '/login'
    end
  end
end

get '/' do
  redirect '/welcome'
end

#get '/edit' do
#  page = Page.welcome
#  "<form action='/save' method='post'><input type='hidden' name='id' value='#{page.id}'/><h2>Edit welcome page</h2><label>Body</label><br/><textarea name='body' rows='28' cols='100'>#{page.body}</textarea><br/><input type='submit' value='Salvar'/></form>"
#end

post '/save' do
  if params[:title].nil?
    params[:title] = 'Welcome'
  end

  if params[:id].to_i.nonzero?
    page = Page.get(params[:id])
  else
    page = Page.new
    #params[:permalink] = params[:title].to_permalink unless params[:title].nil?
  end

  page.attributes = params
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
  @page = Page.first(:permalink => params[:permalink])
  if @page
    haml :page
  else
    redirect '/' + params[:permalink] + '/new'
  end
end

get '/:permalink/new' do
  require_login

  @permalink = params[:permalink]
  haml :new
end

get '/:permalink/edit' do
  require_login

  @page = Page.first(:permalink => params[:permalink])
  haml :edit
end