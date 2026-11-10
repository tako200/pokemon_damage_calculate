# ポケモンがチャンピオンズで覚えられる技（中間テーブル）
class PokemonMove < ApplicationRecord
  belongs_to :pokemon
  belongs_to :move

  validates :move_id, uniqueness: { scope: :pokemon_id }
end
