class CreateMovesAndPokemonMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :moves do |t|
      t.integer :pokeapi_id, null: false
      t.string :name, null: false
      t.string :name_ja, null: false
      # "type" は Rails の STI 用に予約されているため type_name にする
      t.string :type_name, null: false
      # physical / special / status
      t.string :damage_class, null: false
      # 威力が変動する技（けたぐり、ジャイロボール等）や変化技は null
      t.integer :power
      t.integer :accuracy
      t.integer :pp
      t.integer :priority, null: false, default: 0
      # all-opponents / all-other-pokemon ならダブルで範囲技補正（×0.75）の対象
      t.string :target, null: false
      # 連続技の回数（スイープビンタ: 2〜5 など）。連続技でなければ null
      t.integer :min_hits
      t.integer :max_hits

      t.timestamps
    end

    add_index :moves, :pokeapi_id, unique: true
    add_index :moves, :name, unique: true

    # チャンピオンズで覚えられる技（PokeAPI の version_group "champions"）
    create_table :pokemon_moves do |t|
      t.references :pokemon, null: false, foreign_key: { on_delete: :cascade }
      t.references :move, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :pokemon_moves, %i[pokemon_id move_id], unique: true
  end
end
