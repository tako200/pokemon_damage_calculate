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

ActiveRecord::Schema[8.1].define(version: 2026_11_10_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "moves", force: :cascade do |t|
    t.integer "accuracy"
    t.datetime "created_at", null: false
    t.string "damage_class", null: false
    t.integer "max_hits"
    t.integer "min_hits"
    t.string "name", null: false
    t.string "name_ja", null: false
    t.integer "pokeapi_id", null: false
    t.integer "power"
    t.integer "pp"
    t.integer "priority", default: 0, null: false
    t.string "target", null: false
    t.string "type_name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_moves_on_name", unique: true
    t.index ["pokeapi_id"], name: "index_moves_on_pokeapi_id", unique: true
  end

  create_table "pokemon_moves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "move_id", null: false
    t.bigint "pokemon_id", null: false
    t.datetime "updated_at", null: false
    t.index ["move_id"], name: "index_pokemon_moves_on_move_id"
    t.index ["pokemon_id", "move_id"], name: "index_pokemon_moves_on_pokemon_id_and_move_id", unique: true
    t.index ["pokemon_id"], name: "index_pokemon_moves_on_pokemon_id"
  end

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

  add_foreign_key "pokemon_moves", "moves", on_delete: :cascade
  add_foreign_key "pokemon_moves", "pokemons", on_delete: :cascade
end
