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

ActiveRecord::Schema.define(version: 20140626184610) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "completions", force: true do |t|
    t.integer  "learner_id",  null: false
    t.integer  "exercise_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "completions", ["learner_id"], name: "index_completions_on_learner_id", using: :btree

  create_table "exercises", force: true do |t|
    t.integer "topic_id",              null: false
    t.integer "topic_num",             null: false
    t.string  "color",                 null: false
    t.text    "json",                  null: false
    t.integer "rep_num",   default: 1, null: false
  end

  add_index "exercises", ["topic_id", "color", "rep_num"], name: "index_exercises_on_topic_id_and_color_and_rep_num", unique: true, using: :btree
  add_index "exercises", ["topic_num", "color"], name: "index_exercises_on_topic_num_and_color", using: :btree

  create_table "learners", force: true do |t|
    t.string   "http_referer"
    t.string   "user_agent"
    t.string   "remote_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topics", force: true do |t|
    t.integer "num",                null: false
    t.string  "features",           null: false
    t.string  "title",              null: false
    t.string  "title_html"
    t.string  "level",              null: false
    t.string  "youtube_id"
    t.string  "nickname",           null: false
    t.boolean "under_construction", null: false
  end

  add_index "topics", ["nickname"], name: "index_topics_on_nickname", unique: true, using: :btree
  add_index "topics", ["num"], name: "index_topics_on_num", using: :btree
  add_index "topics", ["title"], name: "index_topics_on_title", unique: true, using: :btree
  add_index "topics", ["youtube_id"], name: "index_topics_on_youtube_id", using: :btree

  create_table "tutor_exercise_groups", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tutor_exercises", force: true do |t|
    t.string   "task_id",                 limit: 4, null: false
    t.integer  "tutor_exercise_group_id",           null: false
    t.string   "task_id_substring"
    t.text     "yaml"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tutor_exercises", ["task_id"], name: "index_tutor_exercises_on_task_id", using: :btree
  add_index "tutor_exercises", ["task_id_substring"], name: "index_tutor_exercises_on_task_id_substring", using: :btree

  create_table "tutor_saves", force: true do |t|
    t.integer  "user_id",              null: false
    t.string   "task_id",    limit: 4, null: false
    t.boolean  "is_current",           null: false
    t.text     "code",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tutor_saves", ["task_id"], name: "index_tutor_saves_on_task_id", using: :btree
  add_index "tutor_saves", ["user_id"], name: "index_tutor_saves_on_user_id", using: :btree

  add_foreign_key "completions", "exercises", name: "completions_exercise_id_fk"
  add_foreign_key "completions", "learners", name: "completions_learner_id_fk"

  add_foreign_key "exercises", "topics", name: "exercises_topic_id_fk"

end
