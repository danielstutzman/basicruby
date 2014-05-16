class CreateExercises < ActiveRecord::Migration
  def change
    create_table :exercises do |t|
      t.string :path
      t.string :title
      t.string :color
      t.text :yaml
    end
  end
end
