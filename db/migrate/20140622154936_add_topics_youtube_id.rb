class AddTopicsYoutubeId < ActiveRecord::Migration
  def change
    add_column :topics, :youtube_id, :string
    add_index :topics, :youtube_id
  end
end
