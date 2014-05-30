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

    %w[purple yellow blue red green orange].each do |color|
      exercises = topic_yaml[color]
      next if exercises.nil? # just for unfinished topics
      exercises.each_with_index do |exercise, rep_num0|
        Exercise.create! topic_id: topic.id, topic_num: topic.num,
          color: color, rep_num: rep_num0 + 1,
          json: JSON.generate(exercise)
      end
    end
  end
end
