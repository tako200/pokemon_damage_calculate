class Pokemon < ApplicationRecord
  include KanaSearchable

  STAT_KEYS = %i[hp attack defense special_attack special_defense speed].freeze

  has_many :pokemon_moves, dependent: :delete_all
  has_many :moves, through: :pokemon_moves

  validates :pokeapi_id, presence: true, uniqueness: true
  validates :species_id, presence: true
  validates :name, presence: true, uniqueness: true
  validates :name_ja, presence: true
  validates(*STAT_KEYS, presence: true, numericality: { only_integer: true, greater_than: 0 })

  # 日本語名・英語名・フォーム名・図鑑番号であいまい検索する
  scope :search, ->(query) {
    query = query.to_s.strip
    next all if query.empty?
    next where(species_id: query.to_i) if query.match?(/\A\d+\z/)

    kana_search(query, %w[name_ja form_name_ja name])
  }

  scope :dex_order, -> { order(:species_id, :pokeapi_id) }

  # "10100" なら PokeAPI の ID、"raichu-alola" なら英語名で探す
  def self.find_by_key!(key)
    key.to_s.match?(/\A\d+\z/) ? find_by!(pokeapi_id: key) : find_by!(name: key)
  end

  # チャンピオンズで覚える技。
  # メガシンカは元の姿と同じ技を覚えるので、PokeAPI に技のデータが無いときは通常の姿の技を使う
  # （例: garchomp-mega-z）
  def learnable_moves
    return moves unless mega? && !pokemon_moves.exists?

    base_form&.moves || Move.none
  end

  def mega?
    name.match?(/-mega(-|\z)/)
  end

  def base_form
    is_default ? self : Pokemon.find_by(species_id: species_id, is_default: true)
  end

  # 例: "ライチュウ（アローラのすがた）"
  def display_name
    form_name_ja.present? ? "#{name_ja}（#{form_name_ja}）" : name_ja
  end

  def weight_kg
    weight && weight / 10.0
  end

  def base_stats
    STAT_KEYS.index_with { |key| public_send(key) }
  end
end
