class AddTopicsLevel < ActiveRecord::Migration
  def change
    add_column :topics, :level, :string
    Topic.update_all "level = 'beginner'"
    change_column :topics, :level, :string, null: false
  end
end
