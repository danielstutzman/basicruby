# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140622154936) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "exercises", force: true do |t|
    t.integer "topic_id"
    t.integer "topic_num"
    t.string  "color"
    t.text    "json"
    t.integer "rep_num",   default: 1, null: false
  end

  add_index "exercises", ["topic_num", "color"], name: "index_exercises_on_topic_num_and_color", using: :btree

  create_table "topics", force: true do |t|
    t.integer "num"
    t.string  "features"
    t.string  "title"
    t.string  "title_html"
    t.string  "level",      null: false
    t.string  "youtube_id"
  end

  add_index "topics", ["num"], name: "index_topics_on_num", using: :btree
  add_index "topics", ["youtube_id"], name: "index_topics_on_youtube_id", using: :btree

end
