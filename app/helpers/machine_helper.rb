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
  def level_picker current_level_num
    nbsp = "\xc2\xa0"
    options = [5, 4, 3, 2, 1].map do |level_num|
      "#{nbsp}Level #{level_num}#{nbsp}"
    end
    current_option = "#{nbsp}Level #{current_level_num}#{nbsp}"
    select_tag :level, options_for_select(options, current_option),
      class: 'level-picker'
  end
end
