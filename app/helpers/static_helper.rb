module StaticHelper
  def level_indicator topic_num, color_initial, level_num
    next_level_num = [4, level_num + 1].min
    href = "/#{topic_num}.#{next_level_num}#{color_initial}"
    html = "<a class='level-indicator level-#{level_num}' href='#{href}'></a>"
    html.html_safe
  end
end
