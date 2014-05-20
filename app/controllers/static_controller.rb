class StaticController < ApplicationController
  def index
    @topics = Topic.order(:num)
    @topics.reject! do |topic|
      topic.title == 'Demo of advanced debugger features'
    end
  end
end
