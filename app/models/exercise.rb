require 'json'

class Exercise < ActiveRecord::Base
  belongs_to :topic

  def self.color_initial_to_color
    {
      'y' => 'yellow',
      'b' => 'blue',
      'r' => 'red',
      'g' => 'green',
      'o' => 'orange',
    }
  end
  def self.find_by_path path
    if match = path.match(/^([0-9]+)\.([1-4])([YBRGO])$/i)
      topic_num = match[1]
      level_num = match[2]
      if self.color_initial_to_color.has_key? match[3].downcase
        color = self.color_initial_to_color[match[3].downcase]
      else
        raise ActiveRecord::RecordNotFound.new
      end
      Exercise.find_by! topic_num: topic_num,
        color: color,
        level_num: level_num
    else
      raise path.inspect
      raise ActiveRecord::RecordNotFound.new
    end
  end

  def path
    [self.topic_num.to_s, '.', self.level_num.to_s, self.color[0].upcase].join
  end
  def path_for_level_num level_num
    [self.topic_num.to_s, '.', level_num.to_s, self.color[0].upcase].join
  end
  def path_for_next_exercise
    next_color =
      case self.color
      when 'yellow' then 'red' # temporary for upcoming demo
      when 'red'    then 'green' # temporary for upcoming demo
      when 'green'  then 'yellow' # temporary for upcoming demo
      end
    next_level_num = self.level_num + ((self.color == 'green') ? 1 : 0)
    return nil if next_level_num >= 5
    [self.topic_num.to_s, '.', next_level_num.to_s, next_color[0].upcase].join
  end

  def title
    self.topic.title
  end

  def json_loaded
    @json_loaded ||= JSON.load self.json
  end

  def color_explanation
    case self.color
    when 'yellow' then 'Demonstration'
    when 'blue'   then 'Prediction'
    when 'red'    then 'Bug-fixing'
    when 'green'  then 'Specification'
    when 'orange' then 'Tricks'
    end
  end
end
