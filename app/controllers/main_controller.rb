class MainController < ApplicationController
  def menu
    @topics = Topic.order(:num)
    @exercises = Exercise.select('topic_id, color').all
    @topic_id_color_exists = @exercises.inject({}) do |accum, exercise|
      accum[[exercise.topic_id, exercise.color]] = true
      accum
    end
  end
  def exercise
    @exercise = Exercise.find_by_path params[:path], params[:rep_num]
  end
end
