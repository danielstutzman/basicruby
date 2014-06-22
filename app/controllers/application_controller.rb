class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :load_learner
  def load_learner
    @learner = Learner.find_by_id(session[:learner_id])
    if @learner.nil?
      @learner              = Learner.new
      @learner.user_agent   = request.user_agent
      @learner.http_referer = request.env['HTTP_REFERER']
      @learner.remote_ip    = request.remote_ip
      @learner.save!
      session[:learner_id] = @learner.id
    end
  end
end
