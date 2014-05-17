module MachineHelper
  def image_tag_for_exercise exercise
    case exercise.color
    when 'gold'
      image_tag 'exercise_icons/light_bulb30.png', width: 30, height: 30
    when 'red'
      image_tag 'exercise_icons/red_bug30.png', width: 30, height: 30
    when 'blue'
      image_tag 'exercise_icons/question_mark30.png', width: 30, height: 30
    end
  end
  def assignment_split_with_br exercise
    lines = @exercise.yaml_loaded['assignment'].split("\n")
    lines.map { |line| h(line) }.join("<br>\n").html_safe
  end
  def convert_title_backticks title
    h(title).gsub(/`(.+)`/, '<code>\1</code>').html_safe
  end
  def document_title exercise
    "#{exercise.path} #{exercise.title.gsub('`', '')}"
  end
end
