module Siniki
  module Markup
    def initialize(html)
      super(html.gsub(/\[\[([\w |]+)\]\]/) do |m|
        title, link = $1.split('|')
        "\"#{title}\":/#{(link||title).to_permalink}"
      end)
    end
  end

  module String
    def to_permalink
      str = Unicode.normalize_KD(self).gsub(/[^\x00-\x7F]/n,'')
      str = str.gsub(/[^-_\s\w]/, ' ').downcase.squeeze(' ').tr(' ', '-')
      str = str.gsub(/-+/, '-').gsub(/^-+/, '').gsub(/-+$/, '')
    end
  end
end

RedCloth.include(Siniki::Markup)
String.send(:include, Siniki::String)
