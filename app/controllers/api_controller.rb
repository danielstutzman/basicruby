class ApiController < ApplicationController

  def menu
    if Rails.env.production?
      @topics = Topic.where(under_construction: false).order(:num)
    else
      @topics = Topic.order(:num)
    end

    @exercises = Exercise.select('id, topic_id, topic_num, color, rep_num'
      ).order(:rep_num)

    exercise_by_id = hash = {}
    @exercises.each do |exercise|
      hash[exercise.id] = exercise
    end

    @topic_id_color_exists = hash = {}
    @exercises.each do |exercise|
      hash[[exercise.topic_id, exercise.color]] = true
    end

    @topic_id_color_num_completions = hash = {}
    @learner.completions.each do |completion|
      exercise = exercise_by_id[completion.exercise_id]
      key = [exercise.topic_id, exercise.color]
      hash[key] = {} if hash[key].nil?
      # in case there are 2 completions with same exercise_id
      hash[key][exercise.id] = true
    end

    # reverse order so last path set is the earliest non-completed exercise
    @topic_id_color_next_path = hash = {}
    @exercises.reverse.each do |exercise|
      key = [exercise.topic_id, exercise.color]
      if (@topic_id_color_num_completions[key] || {})[exercise.id].nil?
        hash[key] = exercise.path
      end
    end
    # if learner completed all the reps, link to the first rep
    @exercises.select { |exercise| exercise.rep_num == 1 }.each do |exercise|
      key = [exercise.topic_id, exercise.color]
      hash[key] = exercise.path if hash[key].nil?
    end
  end

  def exercise
    @exercise = Exercise.find_by_path params[:path], params[:rep_num]
  end

end
