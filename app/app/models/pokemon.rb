class Pokemon < ApplicationRecord
  STAT_KEYS = %i[hp attack defense special_attack special_defense speed].freeze

  validates :pokeapi_id, presence: true, uniqueness: true
  validates :species_id, presence: true
  validates :name, presence: true, uniqueness: true
  validates :name_ja, presence: true
  validates(*STAT_KEYS, presence: true, numericality: { only_integer: true, greater_than: 0 })

  # 日本語名・英語名・フォーム名・図鑑番号であいまい検索する。
  # ひらがなで入力されてもカタカナ名にヒットするよう、両方の表記で検索する。
  scope :search, ->(query) {
    query = query.to_s.strip
    next all if query.empty?
    next where(species_id: query.to_i) if query.match?(/\A\d+\z/)

    patterns = [ query, to_katakana(query) ].uniq.map { |q| "%#{sanitize_sql_like(q)}%" }
    conditions = patterns.map do
      "(pokemons.name_ja ILIKE ? OR pokemons.form_name_ja ILIKE ? OR pokemons.name ILIKE ?)"
    end
    where(conditions.join(" OR "), *patterns.flat_map { |p| [ p ] * 3 })
  }

  scope :dex_order, -> { order(:species_id, :pokeapi_id) }

  def self.to_katakana(str)
    str.tr("ぁ-ゖ", "ァ-ヶ")
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
