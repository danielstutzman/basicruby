class AddExercisesRepNum < ActiveRecord::Migration
  def change
    add_column :exercises, :rep_num, :integer, null: false, default: 1
  end
end
