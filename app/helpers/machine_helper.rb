module MachineHelper
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
end
