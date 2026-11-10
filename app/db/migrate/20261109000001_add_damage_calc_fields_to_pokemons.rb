class AddDamageCalcFieldsToPokemons < ActiveRecord::Migration[8.1]
  def change
    # 特性は日本語名・夢特性フラグも持たせるため jsonb に変更する（データは pokeapi:import で再取り込み）
    # 例: [{ "name" => "rough-skin", "name_ja" => "さめはだ", "is_hidden" => true }]
    remove_column :pokemons, :abilities, :string, array: true, null: false, default: []
    add_column :pokemons, :abilities, :jsonb, null: false, default: []

    # けたぐり・ヘビーボンバー等の威力計算用（PokeAPI と同じ 0.1kg 単位）
    add_column :pokemons, :weight, :integer
  end
end
