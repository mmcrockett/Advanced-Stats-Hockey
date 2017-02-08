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

ActiveRecord::Schema.define(version: 20161024123456) do

  create_table "elos", force: :cascade do |t|
    t.integer  "value",                      null: false
    t.date     "sample_date",                null: false
    t.boolean  "ignore",      default: true, null: false
    t.integer  "team_id"
    t.integer  "game_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "elos", ["game_id"], name: "index_elos_on_game_id"
  add_index "elos", ["team_id"], name: "index_elos_on_team_id"

  create_table "games", force: :cascade do |t|
    t.integer  "home_team_id",                  null: false
    t.integer  "home_score",                    null: false
    t.integer  "away_team_id",                  null: false
    t.integer  "away_score",                    null: false
    t.boolean  "overtime",                      null: false
    t.boolean  "playoff",       default: false, null: false
    t.boolean  "elo_processed", default: false, null: false
    t.date     "game_date",                     null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "seasons", force: :cascade do |t|
    t.string   "name",                         null: false
    t.string   "pointhog_url",                 null: false
    t.boolean  "complete",     default: false, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "franchise",  null: false
    t.integer  "season_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "teams", ["season_id"], name: "index_teams_on_season_id"

  create_table "users", force: :cascade do |t|
    t.string   "username",        null: false
    t.string   "hashed_password", null: false
    t.string   "salt",            null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

end
