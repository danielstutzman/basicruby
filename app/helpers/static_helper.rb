module StaticHelper
  def level_indicator level_num
    icon = case level_num
      when 0 then '&#x25cb;'
      when 1 then '&#x25d4;'
      when 2 then '&#x25d1;'
      when 3 then '&#x25d5;'
      when 4 then '&#x25cf;'
    end
    html = "<a class='level-indicator level-#{level_num}' href='#'>#{icon}</a>"
    html.html_safe
  end
end
