# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_09_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "pokemons", force: :cascade do |t|
    t.jsonb "abilities", default: [], null: false
    t.string "artwork_url"
    t.integer "attack", null: false
    t.datetime "created_at", null: false
    t.integer "defense", null: false
    t.string "form_name_ja"
    t.integer "hp", null: false
    t.boolean "is_default", default: true, null: false
    t.string "name", null: false
    t.string "name_ja", null: false
    t.integer "pokeapi_id", null: false
    t.integer "special_attack", null: false
    t.integer "special_defense", null: false
    t.integer "species_id", null: false
    t.integer "speed", null: false
    t.string "sprite_url"
    t.string "types", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.integer "weight"
    t.index ["name"], name: "index_pokemons_on_name", unique: true
    t.index ["pokeapi_id"], name: "index_pokemons_on_pokeapi_id", unique: true
    t.index ["species_id"], name: "index_pokemons_on_species_id"
  end
end
