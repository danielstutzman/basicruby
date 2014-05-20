class MachineController < ApplicationController
  def exercise
    path = "#{params[:topic_num]}.#{params[:level_and_color]}"
    @exercise = Exercise.find_by_path path
  end
end
