module PokeApi
  # PokeAPI からポケモン（リージョンフォーム等を含む）を取得して pokemons テーブルへ upsert する
  class Importer
    JA_LANGUAGES = %w[ja-hrkt ja].freeze
    STAT_MAP = {
      "hp" => :hp,
      "attack" => :attack,
      "defense" => :defense,
      "special-attack" => :special_attack,
      "special-defense" => :special_defense,
      "speed" => :speed
    }.freeze

    def initialize(client: Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
      @species_names = {}
    end

    # limit を指定すると先頭から指定件数のみ取り込む（動作確認用）
    def call(limit: nil)
      entries = @client.get("pokemon", limit: limit || 100_000, offset: 0).fetch("results")
      failures = []

      entries.each_with_index do |entry, index|
        import_one(entry.fetch("url"))
        @logger.info("[PokeApi::Importer] #{index + 1}/#{entries.size} #{entry["name"]}") if ((index + 1) % 50).zero?
      rescue Client::Error, KeyError, ActiveRecord::ActiveRecordError => e
        failures << entry["name"]
        @logger.warn("[PokeApi::Importer] skip #{entry["name"]}: #{e.message}")
      end

      { imported: entries.size - failures.size, failed: failures }
    end

    def import_one(url)
      data = @client.get(url)
      Pokemon.upsert(build_attributes(data), unique_by: :pokeapi_id)
    end

    private

    def build_attributes(data)
      species_id = data.dig("species", "url").to_s[%r{/pokemon-species/(\d+)}, 1].to_i
      stats = data.fetch("stats").to_h { |s| [ STAT_MAP.fetch(s.dig("stat", "name")), s.fetch("base_stat") ] }

      {
        pokeapi_id: data.fetch("id"),
        species_id: species_id,
        name: data.fetch("name"),
        name_ja: species_name_ja(species_id, data.dig("species", "url")) || data.fetch("name"),
        form_name_ja: data["is_default"] ? nil : form_name_ja(data),
        is_default: data.fetch("is_default"),
        types: data.fetch("types").sort_by { |t| t["slot"] }.map { |t| t.dig("type", "name") },
        abilities: data.fetch("abilities").sort_by { |a| a["slot"] }.map { |a| a.dig("ability", "name") },
        sprite_url: data.dig("sprites", "front_default"),
        artwork_url: data.dig("sprites", "other", "official-artwork", "front_default"),
        **stats
      }
    end

    # 同じ種族のフォーム違いで何度も取得しないようキャッシュする
    def species_name_ja(species_id, url)
      @species_names.fetch(species_id) do
        @species_names[species_id] = japanese_name(@client.get(url).fetch("names"))
      end
    end

    def form_name_ja(data)
      form_url = data.fetch("forms").first&.fetch("url")
      return nil unless form_url

      japanese_name(@client.get(form_url).fetch("form_names"))
    end

    def japanese_name(names)
      JA_LANGUAGES.each do |lang|
        found = names.find { |n| n.dig("language", "name") == lang }
        return found["name"] if found
      end
      nil
    end
  end
end
