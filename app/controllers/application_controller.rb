class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :load_learner


  def options_for_cors
    headers['Access-Control-Allow-Headers'] = 'X-Requested-With'
    headers['Access-Control-Max-Age'] = '86400'
    expires_in 86400.seconds, public: true
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
end
