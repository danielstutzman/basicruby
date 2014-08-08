class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:options]
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

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

  def options 
    # dummy action, OPTIONS should be caught by cors_preflight_check
  end     

  private

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, DELETE, PUT, PATCH'
      headers['Access-Control-Allow-Headers'] = '*, X-Requested-With, X-Prototype-Version, X-CSRF-Token'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, DELETE, PUT, PATCH'
    headers['Access-Control-Max-Age'] = "1728000"
  end

end
