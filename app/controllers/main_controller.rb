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
  def landing_page
    topic = Topic.find_by youtube_id: params[:youtube_id]
    raise ActiveRecord::RecordNotFound if topic.nil?
    # first rep of yellow should be the same code as purple, since YouTube
    #   description promised them 'Interact with this code at...'
    yellow = topic.exercises.find_by color: 'yellow', rep_num: 1
    raise ActiveRecord::RecordNotFound if yellow.nil?
    redirect_to '/' + yellow.path
  end
end
