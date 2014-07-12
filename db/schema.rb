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

ActiveRecord::Schema.define(version: 20140712183126) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "densities", force: true do |t|
    t.integer "statistic_id", null: false
    t.integer "feature_id",   null: false
    t.float   "density",      null: false
  end

  add_index "densities", ["density"], name: "index_densities_on_density", using: :btree
  add_index "densities", ["feature_id"], name: "index_densities_on_feature_id", using: :btree
  add_index "densities", ["statistic_id"], name: "index_densities_on_statistic_id", using: :btree

  create_table "features", force: true do |t|
    t.string  "type",     null: false
    t.string  "name",     null: false
    t.float   "lat",      null: false
    t.float   "lng",      null: false
    t.integer "postcode"
    t.float   "area"
    t.string  "polyline"
  end

  add_index "features", ["lat"], name: "index_features_on_lat", using: :btree
  add_index "features", ["lng"], name: "index_features_on_lng", using: :btree
  add_index "features", ["type"], name: "index_features_on_type", using: :btree

  create_table "sources", force: true do |t|
    t.string "name",        null: false
    t.string "description", null: false
  end

  create_table "statistics", force: true do |t|
    t.integer "source_id",    null: false
    t.integer "parent_id"
    t.string  "name",         null: false
    t.string  "feature_type", null: false
  end

  add_index "statistics", ["parent_id"], name: "index_statistics_on_parent_id", using: :btree
  add_index "statistics", ["source_id"], name: "index_statistics_on_source_id", using: :btree

  create_table "values", force: true do |t|
    t.integer "statistic_id", null: false
    t.integer "feature_id",   null: false
    t.float   "value",        null: false
  end

  add_index "values", ["feature_id"], name: "index_values_on_feature_id", using: :btree
  add_index "values", ["statistic_id"], name: "index_values_on_statistic_id", using: :btree
  add_index "values", ["value"], name: "index_values_on_value", using: :btree

end
