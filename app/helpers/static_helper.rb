module StaticHelper
  def done_indicator topic_num, color_initial
    href = "/#{topic_num}#{color_initial}"
    char = '&#x2610;' # or '&#x2611;'
    html = "<a class='done-indicator' href='#{href}'>#{char}</a>"
    html.html_safe
  end
end
