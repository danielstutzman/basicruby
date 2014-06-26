class TutorExerciseGroup < ActiveRecord::Base
  has_many :tutor_exercises, -> { order :task_id_substring, :id }
end
