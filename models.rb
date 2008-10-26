DataMapper.setup(:default, 'sqlite3:siniki.db')

class Page
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :parent_id, Integer
  property :title, String, :nullable => false
  property :body, Text
  property :html_body, Text
  property :permalink, String, :nullable => false
  property :created_at, DateTime

  before :save, :set_permalink
  before :save, :process_body
  before :save, :timestamps

  belongs_to :page, :child_key => [:parent_id]

  def self.welcome
    Page.first(:permalink => 'welcome')
  end

  def self.header
    Page.first(:permalink => 'header')
  end

  def self.menu
    Page.first(:permalink => 'menu')
  end

  def self.last_version(permalink)
    Page.first(:permalink => permalink, :order => [:created_at.desc])
  end

  private

  def set_permalink(context = :default)
    self.permalink = self.title.to_permalink if self.permalink.nil?
  end

  def process_body
    unless self.body.nil?
      markdown = RDiscount.new(self.body)
      self.html_body = markdown.to_html
    end
  end

  def timestamps
    unless self.id.to_i.nonzero?
      self.created_at = Time.now
    else
      self.updated_at = Time.now
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