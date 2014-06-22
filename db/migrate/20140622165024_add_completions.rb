class AddCompletions < ActiveRecord::Migration
  def change
    create_table :completions do |t|
      t.integer :learner_id,  null: false
      t.integer :exercise_id, null: false
      t.timestamps
    end
    add_index :completions, :learner_id
  end
end
