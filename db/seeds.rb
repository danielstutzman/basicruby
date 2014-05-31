require 'yaml'
require 'json'

Exercise.transaction do
  Topic.delete_all
  Exercise.delete_all

  dir = File.dirname(__FILE__)
  topic_num = 1
  Dir.glob("#{dir}/*.yaml") do |path|
    yaml = YAML.load_file(path)
    p yaml

    topic = Topic.create! num: topic_num + 1,
      title: yaml['title'],
      title_html: yaml['title_html'] || yaml['title'],
      features: yaml['features']

    %w[purple yellow blue red green orange].each do |color|
      exercises = yaml[color]
      next if exercises.nil? # just for unfinished topics
      exercises.each_with_index do |exercise, rep_num0|
        Exercise.create! topic_id: topic.id, topic_num: topic.num,
          color: color, rep_num: rep_num0 + 1,
          json: JSON.generate(exercise)
      end
    end

    topic_num += 1
  end
end
