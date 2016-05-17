require 'yaml'
require 'json'

ActiveRecord::Base.logger = nil
Exercise.transaction do
  dir = File.dirname(__FILE__)
  topic_num = 1

  nickname2count = {}
  Dir.glob("#{dir}/*.yaml").each do |path|
    match = path.match(/\/([0-9]+)_(.*).yaml$/) or raise "Filename doesn't match regex: #{path}"
    nickname = match[2]
    nickname2count[nickname] ||= 0
    nickname2count[nickname] += 1
  end
  dup_nicknames = nickname2count.select { |nickname, count| count > 1 }
  raise "Duplicate nicknames: #{dup_nicknames}" if dup_nicknames.size > 0

  Dir.glob("#{dir}/*.yaml").sort.each do |path|
    puts path
    yaml = YAML.load_file(path)
    match = path.match(/\/([0-9]+)_(.*).yaml$/)
    nickname = match[2]

    # update old topic so foreign keys aren't broken
    topic = Topic.find_by(nickname: nickname) ||
      Topic.new(nickname: nickname)
    topic.num        = topic_num
    topic.title      = yaml['title']
    topic.title_html = yaml['title_html'] || yaml['title']
    topic.level      = yaml['level']
    topic.features   = yaml['features']
    topic.youtube_id = yaml['purple'] && yaml['purple'][0] &&
                       yaml['purple'][0]['youtube_id']
    topic.under_construction = yaml['under_construction']
    topic.save!

    %w[purple yellow blue red green orange].each do |color|
      exercises = yaml[color]
      next if exercises.nil? # just for unfinished topics

      exercises.each_with_index do |exercise_from_yaml, rep_num0|
        rep_num = rep_num0 + 1

        # update old exercise so foreign keys aren't broken
        exercise = Exercise.find_by(topic_id: topic.id,
            color: color, rep_num: rep_num) ||
          Exercise.new(topic_id: topic.id, color: color, rep_num: rep_num)
        exercise.topic_num = topic.num
        exercise.json = JSON.generate(exercise_from_yaml)
        exercise.save!
      end
    end

    topic_num += 1
  end
end
