module PokeApi
  module Localization
    # ja-hrkt（かな表記）を優先し、なければ ja（漢字を含む）を使う
    JA_LANGUAGES = %w[ja-hrkt ja].freeze

    module_function

    # PokeAPI の names / form_names 配列から日本語名を取り出す
    def japanese_name(names)
      JA_LANGUAGES.each do |lang|
        found = names.find { |n| n.dig("language", "name") == lang }
        return found["name"] if found
      end
      nil
    end
  end
end
