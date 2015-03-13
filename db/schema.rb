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

ActiveRecord::Schema.define(version: 20150312224539) do

  create_table "player_infos", force: :cascade do |t|
    t.text    "info"
    t.integer "info_no"
  end

  add_index "player_infos", ["info_no"], name: "index_player_infos_on_info_no"

  create_table "players", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "name"
    t.integer  "uid"
    t.integer  "team_uid"
    t.integer  "league_uid"
    t.integer  "grade"
    t.text     "info"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "position"
    t.integer  "player_info_id"
  end

  add_index "players", ["player_info_id"], name: "index_players_on_player_info_id"
  add_index "players", ["team_id"], name: "index_players_on_team_id"
  add_index "players", ["uid"], name: "index_players_on_uid"

  create_table "teams", force: :cascade do |t|
    t.string   "login_name"
    t.integer  "uid"
    t.integer  "team_uid"
    t.integer  "league_uid"
    t.integer  "member_count"
    t.integer  "league_count"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "teamname"
    t.string   "team_sign"
    t.integer  "gp_amount"
    t.boolean  "registered",   default: false
    t.string   "login_pwd"
  end

  add_index "teams", ["login_name"], name: "index_teams_on_login_name"

end
