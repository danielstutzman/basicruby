class Topic < ActiveRecord::Base
  has_many :exercises

  def title_text
    self.title.gsub('`', '')
  end
  def title_html
    attributes[:title_html] ||
      self.title.gsub(/`(.*?)`/, '<code>\1</code>').html_safe
  end
end
