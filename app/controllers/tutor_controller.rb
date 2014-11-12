class TutorController < ApplicationController
  #protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, if: :json_request?

  def api_welcome
    @groups = TutorExerciseGroup.order(:id)
  end

  def api_exercise
    current_user = Learner.find_by(id: session[:user_id])
    if current_user.nil?
      current_user = Learner.create!
      session[:user_id] = current_user.id
    end

    task_id = params[:task_id]
    exercise = TutorExercise.find_by_task_id(task_id)
    if exercise.nil?
      raise ActionController::RoutingError.new('Exercise not found')
    end
    if exercise.yaml.nil?
      raise ActionController::RoutingError.new('No code for that exercise')
    end
    begin
      @exercise = exercise.yaml_loaded
    rescue Psych::SyntaxError => e
      raise "#{e.class}: #{e} with #{exercise.yaml}"
    end

    old_record =
      TutorSave.where({
        :user_id     => current_user.id,
        :task_id     => task_id,
        :is_current  => true
      }).first
    if old_record
      @user_code = old_record.code
    else
      @user_code = @exercise['starting_code'] || ''
    end

    @exercise['task_id']   = task_id
    @exercise['user_code'] = @user_code

    render json: @exercise
  end

  def api_save_tutor_code
    current_user = Learner.find_by(id: session[:user_id])
    task_id = params[:task_id]
    user_code = params[:user_code_textarea]
    TutorSave.transaction do
      TutorSave.where({
        :user_id      => current_user.id,
        :task_id      => task_id,
        :is_current   => true
      }).update_all(:is_current => 'f')
      TutorSave.create({
        :user_id      => current_user.id,
        :task_id      => task_id,
        :is_current   => true,
        :code         => user_code,
      })
    end
    render json: [], status: :ok
  end

  def api_discard_tutor_code
    current_user = Learner.find_by(id: session[:user_id])
    task_id = params[:task_id]
    TutorSave.where({
      :user_id      => current_user.id,
      :task_id      => task_id,
      :is_current   => true
    }).update_all(:is_current => false)
    render json: [], status: :ok
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
