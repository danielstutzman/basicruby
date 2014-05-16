class MachineController < ApplicationController
  def exercise
    keys = %w[unit_num lesson_num exercise_num]
    path = keys.map { |key| params[key.intern] }.join('.')
    @exercise = Exercise.find_by! path: path
  end
end
