class MachineController < ApplicationController
  def exercise
    @exercise = Exercise.find_by_path params[:path]
  end
end
