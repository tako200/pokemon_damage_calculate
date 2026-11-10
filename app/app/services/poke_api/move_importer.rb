module PokeApi
  # PokeAPI から技を取得して moves テーブルへ upsert する
  class MoveImporter
    def initialize(client: Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
    end

    # limit を指定すると先頭から指定件数のみ取り込む（動作確認用）
    def call(limit: nil)
      entries = @client.get("move", limit: limit || 100_000, offset: 0).fetch("results")
      failures = []

      entries.each_with_index do |entry, index|
        import_one(entry.fetch("url"))
        @logger.info("[PokeApi::MoveImporter] #{index + 1}/#{entries.size} #{entry["name"]}") if ((index + 1) % 100).zero?
      rescue Client::Error, KeyError, ActiveRecord::ActiveRecordError => e
        failures << entry["name"]
        @logger.warn("[PokeApi::MoveImporter] skip #{entry["name"]}: #{e.message}")
      end

      { imported: entries.size - failures.size, failed: failures }
    end

    def import_one(url)
      data = @client.get(url)
      Move.upsert(build_attributes(data), unique_by: :pokeapi_id)
    end

    private

    def build_attributes(data)
      {
        pokeapi_id: data.fetch("id"),
        name: data.fetch("name"),
        name_ja: Localization.japanese_name(data.fetch("names")) || data.fetch("name"),
        type_name: data.dig("type", "name"),
        damage_class: data.dig("damage_class", "name"),
        power: data["power"],
        accuracy: data["accuracy"],
        pp: data["pp"],
        priority: data.fetch("priority"),
        target: data.dig("target", "name"),
        min_hits: data.dig("meta", "min_hits"),
        max_hits: data.dig("meta", "max_hits")
      }
    end
  end
end
