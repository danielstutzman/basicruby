require 'yaml'
require 'json'

ActiveRecord::Base.logger = nil
Exercise.transaction do
  Topic.delete_all
  Exercise.delete_all

  dir = File.dirname(__FILE__)
  topic_num = 1
  Dir.glob("#{dir}/*.yaml").sort.each do |path|
    puts path
    yaml = YAML.load_file(path)

    topic = Topic.create! num: topic_num,
      title:      yaml['title'],
      title_html: yaml['title_html'] || yaml['title'],
      level:      yaml['level'],
      features:   yaml['features']

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
