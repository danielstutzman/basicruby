require 'json'

class Exercise < ActiveRecord::Base
  belongs_to :topic

  def self.color_initial_to_color
    {
      'p' => 'purple',
      'y' => 'yellow',
      'b' => 'blue',
      'r' => 'red',
      'g' => 'green',
      'o' => 'orange',
    }
  end
  def self.find_by_path path, rep_num
    if match = path.match(/^([0-9]+)([PYBRGO])$/i)
      topic_num = match[1]
      if self.color_initial_to_color.has_key? match[2].downcase
        color = self.color_initial_to_color[match[2].downcase]
      else
        raise ActiveRecord::RecordNotFound.new
      end
      Exercise.find_by! topic_num: topic_num, color: color,
        rep_num: rep_num ? rep_num.to_i : 1
    else
      raise ActiveRecord::RecordNotFound.new
    end
  end

  def path
    [self.topic_num.to_s,  self.color[0].upcase].join
  end
  def path_for_next_exercise
    next_color =
      case self.color
      when 'purple' then 'yellow'
      when 'yellow' then 'blue'
      when 'blue'   then 'red'
      when 'red'    then 'green'
      when 'green'  then 'purple'
      end
    next_topic_num = self.topic_num + ((self.color == 'green') ? 1 : 0)
    "/#{next_topic_num}#{next_color[0].upcase}"
  end
  def path_for_next_rep
    if Exercise.find_by topic_num: self.topic_num, color: self.color,
        rep_num: self.rep_num + 1
      "/#{self.topic_num}#{self.color[0].upcase}/#{self.rep_num + 1}"
    else
      nil
    end
  end

  def title
    self.topic.title
  end

  def json_loaded
    @json_loaded ||= JSON.load self.json
  end

  def color_explanation
    case self.color
    when 'purple' then 'Introduction'
    when 'yellow' then 'Example'
    when 'blue'   then 'Prediction'
    when 'red'    then 'Bug-fixing'
    when 'green'  then 'Specification'
    when 'orange' then 'Tricks'
    end
  end
end
