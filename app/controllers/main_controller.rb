class MainController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:mark_complete]

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
  def landing_page
    topic = Topic.find_by youtube_id: params[:youtube_id]
    raise ActiveRecord::RecordNotFound if topic.nil?
    # first rep of yellow should be the same code as purple, since YouTube
    #   description promised them 'Interact with this code at...'
    yellow = topic.exercises.find_by color: 'yellow', rep_num: 1
    raise ActiveRecord::RecordNotFound if yellow.nil?
    redirect_to URI.parse(yellow.path).path
  end
  def mark_complete
    Completion.create! learner_id: @learner.id,
      exercise_id: params[:exercise_id]
    redirect_to URI.parse(params[:next_url]).path
  end
end
