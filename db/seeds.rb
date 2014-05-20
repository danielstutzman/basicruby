require 'yaml'
require 'json'

Exercise.transaction do
  topics = YAML.load_file("#{File.dirname(__FILE__)}/curriculum.yaml")

  Topic.delete_all
  Exercise.delete_all

  topics.each_with_index do |topic_yaml, num0|
    topic = Topic.create! num: num0 + 1,
      title: topic_yaml['title'],
      title_html: topic_yaml['title_html'] || topic_yaml['title'],
      features: topic_yaml['features']

    %w[yellow blue red green orange].each do |color|
      exercise = topic_yaml[color]
      next if exercise.nil? # just for unfinished topics
      Exercise.create! topic_id: topic.id, topic_num: topic.num,
        color: color, json: JSON.generate(exercise)
    end
  end
end
