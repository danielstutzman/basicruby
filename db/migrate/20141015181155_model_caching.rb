class ModelCaching < ActiveRecord::Migration
  def change
    change_table :topics do |t|
      t.timestamps
    end
    change_table :exercises do |t|
      t.timestamps
    end
  end
end
