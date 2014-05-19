module StaticHelper
  def level_indicator level_num
    "<a class='level-indicator level-#{level_num}' href='#'></a>".html_safe
  end
end
