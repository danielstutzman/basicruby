json.topic do |topic|
  topic.num   @exercise.topic.num
  topic.title @exercise.topic.title
end
json.exercise_id @exercise.id
json.color       @exercise.color
json.rep_num     @exercise.rep_num
json.features    @exercise.topic.features.split(' ')
json.json        @exercise.json_loaded
json.paths do |paths|
  paths.next_exercise @exercise.path_for_next_exercise
  paths.next_rep      @exercise.path_for_next_rep
end
