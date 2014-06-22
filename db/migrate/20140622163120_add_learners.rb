class AddLearners < ActiveRecord::Migration
  def change
    create_table :learners do |t|
      t.string :http_referer
      t.string :user_agent
      t.string :remote_ip
      t.timestamps
    end
  end
end
