module PokeApi
  # PokeAPI からポケモンを取得して pokemons テーブルへ upsert する。
  # あわせて、チャンピオンズで覚えられる技を pokemon_moves に保存する（先に MoveImporter を実行しておくこと）。
  # ポケモンチャンピオンズのダメージ計算用なので、対戦で使えないフォームは取り込まない。
  class PokemonImporter
    # PokeAPI の version_group。この作品で覚えられる技だけを保存する
    VERSION_GROUP = "champions".freeze

    STAT_MAP = {
      "hp" => :hp,
      "attack" => :attack,
      "defense" => :defense,
      "special-attack" => :special_attack,
      "special-defense" => :special_defense,
      "speed" => :speed
    }.freeze

    # 対戦で使えない / 見た目だけが違うフォーム
    EXCLUDED_NAME_PATTERNS = [
      /-gmax\z/,                                                # キョダイマックス（チャンピオンズにダイマックスはない）
      /-totem/,                                                 # ぬしポケモン
      /\A(pikachu|eevee)-starter\z/,                            # Let's Go の相棒
      /\Apikachu-(rock-star|belle|pop-star|phd|libre|cosplay)\z/, # おきがえピカチュウ
      /\Apikachu-.+-cap\z/,                                     # キャップピカチュウ
      /\Aeternatus-eternamax\z/                                 # ムゲンダイマックス
    ].freeze

    def self.excluded?(name)
      EXCLUDED_NAME_PATTERNS.any? { |pattern| pattern.match?(name) }
    end

    def initialize(client: Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
      @species_names = {}
      @ability_names = {}
    end

    # limit を指定すると先頭から指定件数のみ取り込む（動作確認用）
    def call(limit: nil)
      @move_ids = Move.pluck(:name, :id).to_h
      @logger.warn("[PokeApi::PokemonImporter] moves テーブルが空です。先に pokeapi:import_moves を実行してください") if @move_ids.empty?

      entries = @client.get("pokemon", limit: limit || 100_000, offset: 0).fetch("results")
      excluded, targets = entries.partition { |entry| self.class.excluded?(entry.fetch("name")) }
      failures = []

      targets.each_with_index do |entry, index|
        import_one(entry.fetch("url"))
        @logger.info("[PokeApi::PokemonImporter] #{index + 1}/#{targets.size} #{entry["name"]}") if ((index + 1) % 50).zero?
      rescue Client::Error, KeyError, ActiveRecord::ActiveRecordError => e
        failures << entry["name"]
        @logger.warn("[PokeApi::PokemonImporter] skip #{entry["name"]}: #{e.message}")
      end

      # 以前の取り込みで入っていた除外対象を削除する（pokemon_moves は外部キーの on_delete: :cascade で消える）
      removed = Pokemon.where(name: excluded.map { |entry| entry["name"] }).delete_all

      { imported: targets.size - failures.size, excluded: excluded.size, removed: removed, failed: failures }
    end

    def import_one(url)
      data = @client.get(url)

      Pokemon.transaction do
        pokemon_id = Pokemon.upsert(build_attributes(data), unique_by: :pokeapi_id, returning: :id).rows.first.first
        sync_moves(pokemon_id, data.fetch("moves"))
      end
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
        abilities: build_abilities(data.fetch("abilities")),
        weight: data["weight"],
        sprite_url: data.dig("sprites", "front_default"),
        artwork_url: data.dig("sprites", "other", "official-artwork", "front_default"),
        **stats
      }
    end

    def build_abilities(abilities)
      abilities.sort_by { |a| a["slot"] }.map do |a|
        name = a.dig("ability", "name")
        { name: name, name_ja: ability_name_ja(a.dig("ability", "url")) || name, is_hidden: a.fetch("is_hidden") }
      end
    end

    # チャンピオンズで覚えられる技に入れ替える（覚えなくなった技は削除）
    def sync_moves(pokemon_id, moves)
      names = moves.select { |m| m.fetch("version_group_details").any? { |v| v.dig("version_group", "name") == VERSION_GROUP } }
                   .map { |m| m.dig("move", "name") }
      move_ids = @move_ids.values_at(*names).compact.uniq

      PokemonMove.where(pokemon_id: pokemon_id).where.not(move_id: move_ids).delete_all
      return if move_ids.empty?

      PokemonMove.insert_all(move_ids.map { |move_id| { pokemon_id: pokemon_id, move_id: move_id } },
                             unique_by: %i[pokemon_id move_id])
    end

    # 同じ種族のフォーム違いで何度も取得しないようキャッシュする
    def species_name_ja(species_id, url)
      @species_names.fetch(species_id) do
        @species_names[species_id] = Localization.japanese_name(@client.get(url).fetch("names"))
      end
    end

    # 特性は多くのポケモンで共通なのでキャッシュする
    def ability_name_ja(url)
      @ability_names.fetch(url) do
        @ability_names[url] = Localization.japanese_name(@client.get(url).fetch("names"))
      end
    end

    def form_name_ja(data)
      form_url = data.fetch("forms").first&.fetch("url")
      return nil unless form_url

      Localization.japanese_name(@client.get(form_url).fetch("form_names"))
    end
  end
end
