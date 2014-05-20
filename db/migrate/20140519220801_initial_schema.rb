class InitialSchema < ActiveRecord::Migration
  def change
    create_table :topics do |t|
      t.integer :num
      t.string :features
      t.string :title
    end
    create_table :exercises do |t|
      t.integer :topic_id
      t.integer :topic_num
      t.string :color
      t.integer :level_num
      t.text :json
    end
    add_index :exercises, [:topic_num, :color, :level_num]
  end
end
