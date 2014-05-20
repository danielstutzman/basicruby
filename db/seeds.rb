require 'yaml'
require 'json'

Exercise.transaction do
  topics = YAML.load_file("#{File.dirname(__FILE__)}/curriculum.yaml")

  Topic.delete_all
  Exercise.delete_all

  topics.each_with_index do |topic_yaml, num0|
    topic = Topic.create! num: num0 + 1,
      title: topic_yaml['title'],
      features: topic_yaml['features']

    [1, 2, 3, 4].each_with_index do |level_num|
      key = "level #{level_num}"
      topic_yaml[key].each do |color, exercise|
        Exercise.create! topic_id: topic.id, topic_num: topic.num,
          color: color, level_num: level_num,
          json: JSON.generate(exercise)
      end
    end
  end
end
