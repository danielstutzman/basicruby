class MergeInRubyTutor < ActiveRecord::Migration
  def change
    create_table :tutor_saves do |t|
      t.integer :user_id,      null: false
      t.string  :task_id,      null: false, limit: 4
      t.boolean :is_current,   null: false
      t.text    :code,         null: false
      t.timestamps
    end
    add_index :tutor_saves, :user_id
    add_index :tutor_saves, :task_id

    create_table :tutor_exercises do |t|
      t.string  :task_id,                 null: false, limit: 4
      t.integer :tutor_exercise_group_id, null: false
      t.string  :task_id_substring
      t.text    :yaml
      t.timestamps
    end
    add_index :tutor_exercises, :task_id
    add_index :tutor_exercises, :task_id_substring

    create_table :tutor_exercise_groups do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
