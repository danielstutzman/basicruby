class ApiController < ApplicationController
  #protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, if: :json_request?

  def root
    render text: 'This is the backend server.  It should be accessed through XHR requests from a JavaScript frontend, not directly.'
  end

  def easyxdm
    response.headers.delete 'X-Frame-Options'
    render :easyxdm, layout: false
  end

  def all_exercises
    render json: Exercise.select(:id, :topic_num, :color, :rep_num).order(:id)
  end

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
    path, rep_num = params[:path], params[:rep_num]
    @exercise = Exercise.find_by_path path, rep_num
  end

  def mark_complete
    exercise_id = params[:exercise_id]
    Completion.create! learner_id: @learner.id, exercise_id: exercise_id
    render json: ['ok']
  end

  private

  def json_request?
    request.format.json?
  end

  rescue_from Exception do |e|
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE'
    logger.error "#{e.class} #{e}"
    render status: 500, json: { error: [e.class.to_s, e.to_s] }
  end

end
