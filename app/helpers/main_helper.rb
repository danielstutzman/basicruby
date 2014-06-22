UNCHECKED_BOX = '&#x2610;'
CHECKED_BOX   = '&#x2611;'

module MainHelper
  def done_indicator topic_num, color_initial, num_completions, next_path
    if color_initial == 'P' # purple: there's only one video to watch
      text = (num_completions > 0) ? CHECKED_BOX : UNCHECKED_BOX
    else
      text = UNCHECKED_BOX
      if num_completions > 0
        text += "<div class='num-completions'>#{num_completions}</div>"
      end
    end
    "<a class='done-indicator' href='#{next_path}'>#{text}</a>".html_safe
  end
end
