class Constraints < ActiveRecord::Migration
  def up
    change_column :exercises, :topic_id,  :integer, null: false
    change_column :exercises, :topic_num, :integer, null: false
    change_column :exercises, :color,     :string,  null: false
    change_column :exercises, :json,      :text,    null: false
    change_column :topics,    :num,       :integer, null: false
    change_column :topics,    :features,  :string,  null: false
    change_column :topics,    :title,     :string,  null: false

    add_index :topics, :title, unique: true

    add_foreign_key :completions, :learners
    add_foreign_key :completions, :exercises
    add_foreign_key :exercises,   :topics
  end
  def down
    change_column :exercises, :topic_id,  :integer, null: true
    change_column :exercises, :topic_num, :integer, null: true
    change_column :exercises, :color,     :string,  null: true
    change_column :exercises, :json,      :text,    null: true
    change_column :topics,    :num,       :integer, null: true
    change_column :topics,    :features,  :string,  null: true
    change_column :topics,    :title,     :string,  null: true

    remove_index :topics, :title

    remove_foreign_key :completions, :learners
    remove_foreign_key :completions, :exercises
    remove_foreign_key :exercises,   :topics
  end
end
