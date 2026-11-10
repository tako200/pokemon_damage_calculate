# ひらがな・カタカナのどちらで入力されても部分一致で検索できるようにする。
# 例: "がぶ" → "ガブリアス"、"ジシン" → "じしん"
module KanaSearchable
  extend ActiveSupport::Concern

  class_methods do
    def kana_variants(query)
      [ query, query.tr("ぁ-ゖ", "ァ-ヶ"), query.tr("ァ-ヶ", "ぁ-ゖ") ].uniq
    end

    # columns のいずれかに、入力（とそのひらがな・カタカナ変換）を含む行を返す
    def kana_search(query, columns)
      patterns = kana_variants(query).map { |q| "%#{sanitize_sql_like(q)}%" }
      clauses = patterns.flat_map { columns.map { |column| "#{table_name}.#{column} ILIKE ?" } }
      where(clauses.join(" OR "), *patterns.flat_map { |pattern| [ pattern ] * columns.size })
    end
  end
end
