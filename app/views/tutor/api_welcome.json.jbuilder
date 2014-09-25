json.groups do
  json.array! @groups do |group|
    json.id   group.id
    json.name group.name
    json.exercises do
      json.array! group.tutor_exercises do |exercise|
        json.task_id     exercise.task_id
        json.description YAML.load(exercise.yaml)['description']
      end
    end
  end
end
