class AddTopicsUnderConstruction < ActiveRecord::Migration
  def up
    add_column :topics, :under_construction, :boolean, null: false, default: false
    change_column_default :topics, :under_construction, nil
  end
  def down
    remove_column :topics, :under_construction
  end
end
