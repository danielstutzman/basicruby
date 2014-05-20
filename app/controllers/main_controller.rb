class MainController < ApplicationController
  def menu
    @topics = Topic.order(:num)
    @topics.reject! do |topic|
      topic.title == 'Demo of advanced debugger features'
    end
  end
  def exercise
    @exercise = Exercise.find_by_path params[:path]
  end
end
