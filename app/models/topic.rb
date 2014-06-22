class Topic < ActiveRecord::Base
  has_many :exercises

  def title_text
    self.title.gsub('`', '')
  end
  def title_html
    html = attributes['title_html'] || self.title
    html.gsub! /`(.*?)`/, '<code>\1</code>'
    html.html_safe
  end
end
