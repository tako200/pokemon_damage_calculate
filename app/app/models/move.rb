class Move < ApplicationRecord
  include KanaSearchable

  DAMAGE_CLASSES = %w[physical special status].freeze
  # ダブルバトルで範囲技補正（×0.75）がかかる対象
  SPREAD_TARGETS = %w[all-opponents all-other-pokemon].freeze

  has_many :pokemon_moves, dependent: :delete_all
  has_many :pokemons, through: :pokemon_moves

  validates :pokeapi_id, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates :name_ja, :type_name, :target, presence: true
  validates :damage_class, inclusion: { in: DAMAGE_CLASSES }

  scope :search, ->(query) {
    query = query.to_s.strip
    query.empty? ? all : kana_search(query, %w[name_ja name])
  }

  # damage_class: "physical" / "special" / "status" / "all"。
  # 省略時はダメージ計算に使う攻撃技（物理・特殊）だけを返す。
  scope :with_damage_class, ->(damage_class) {
    case damage_class.presence
    when nil then where.not(damage_class: "status")
    when "all" then all
    else where(damage_class: damage_class)
    end
  }

  scope :with_type, ->(type_name) { type_name.present? ? where(type_name: type_name) : all }

  # 威力の高い順（威力が変動する技・変化技は後ろ）
  scope :power_order, -> { order(arel_table[:power].desc.nulls_last, :pokeapi_id) }

  # "89" なら PokeAPI の ID、"earthquake" なら英語名で探す
  def self.find_by_key!(key)
    key.to_s.match?(/\A\d+\z/) ? find_by!(pokeapi_id: key) : find_by!(name: key)
  end

  def spread?
    SPREAD_TARGETS.include?(target)
  end
end
