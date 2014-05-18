module MachineHelper
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
