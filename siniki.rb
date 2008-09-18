require 'rubygems'
require 'dm-core'
require 'sinatra'
require 'unicode'
require 'rdiscount'

DataMapper.setup(:default, 'sqlite3:siniki.db')

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

get '/setup' do
  DataMapper.auto_migrate!
  
  page = Page.new
  page.attributes = {:title => 'Welcome'}
  page.save
  
  "siniki is ready to run!"
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
  "<form action='/save' method='post'><h2>Edit welcome page</h2><label>Title</label><br/><input type='text' name='title'/><br/><label>Body</label><br/><textarea name='body' rows='28' cols='100'></textarea><br/><input type='submit' value='Salvar'/></form>"
end

get '/:permalink' do
  page = Page.first(:permalink => params[:permalink])
  if page
    "<h2>#{page.title}</h2>#{page.processed_body}"
  else
    "Page does not exists (#{params[:permalink]})"
  end
end

get '/:permalink/edit' do
  page = Page.first(:permalink => params[:permalink])
  "<form action='/save' method='post'><input type='hidden' name='id' value='#{page.id}'/><h2>Edit page</h2><label>Title</label><br/><input type='text' name='title' value='#{page.title}'/><br/><label>Body</label><br/><textarea name='body' rows='28' cols='100'>#{page.body}</textarea><br/><input type='submit' value='Salvar'/></form>"
end
