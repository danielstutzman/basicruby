module ExerciseHelper
  def assignment_split_with_br exercise
    assignment = @exercise.json_loaded['assignment']
    if assignment
      lines = @exercise.json_loaded['assignment'].split("\n")
      lines.map! { |line| h(line) }
      lines.map! { |line| line.gsub(/`(.*?)`/, '<code>\1</code>') }
      lines.join("<br>\n").html_safe
    else
      "<br clear='all'>".html_safe
    end
  end
  def convert_title_backticks title
    h(title).gsub(/`(.+)`/, '<code>\1</code>').html_safe
  end
  def document_title exercise
    "Basic Ruby #{exercise.path}"
  end
  def video_url topic_num
    image_url("topic#{topic_num}.mp4")
  end
  def video_poster_url topic_num
    image_url("topic#{topic_num}_poster.png")
  end
end
