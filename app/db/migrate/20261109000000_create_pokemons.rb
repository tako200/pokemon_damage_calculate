class CreatePokemons < ActiveRecord::Migration[8.1]
  def change
    create_table :pokemons do |t|
      # PokeAPI の /pokemon/{id}（リージョンフォーム等は 10001 以降）
      t.integer :pokeapi_id, null: false
      # 全国図鑑番号（/pokemon-species/{id}）
      t.integer :species_id, null: false
      t.string :name, null: false
      t.string :name_ja, null: false
      t.string :form_name_ja
      t.boolean :is_default, null: false, default: true
      t.string :types, array: true, null: false, default: []
      t.string :abilities, array: true, null: false, default: []

      # 種族値
      t.integer :hp, null: false
      t.integer :attack, null: false
      t.integer :defense, null: false
      t.integer :special_attack, null: false
      t.integer :special_defense, null: false
      t.integer :speed, null: false

      t.string :sprite_url
      t.string :artwork_url

      t.timestamps
    end

    add_index :pokemons, :pokeapi_id, unique: true
    add_index :pokemons, :name, unique: true
    add_index :pokemons, :species_id
  end
end
