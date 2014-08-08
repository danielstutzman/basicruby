class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_filter :set_access_control_headers

  before_action :load_learner

  skip_before_filter :verify_authenticity_token, only: :options_for_cors

  def options_for_cors
    headers['Access-Control-Allow-Headers'] = 'X-Requested-With'
    head(:ok)
  end

  private
  def load_learner
    @learner = Learner.find_by_id(session[:learner_id])
    if @learner.nil?
      @learner              = Learner.new
      @learner.user_agent   = request.user_agent
      @learner.http_referer = request.env['HTTP_REFERER']
      @learner.remote_ip    = request.remote_ip
      unless request.user_agent =~ /(monitis|Googlebot|baiduspider|Exabot|Yahoo! Slurp|DotBot|bingbot|MJ12bot|panscient.com|YandexBot)/
        @learner.save!
        session[:learner_id] = @learner.id
      end
    end
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE'
  end
end
