require "test_helper"

class PokeApi::ImporterTest < ActiveSupport::TestCase
  # URL ごとに固定レスポンスを返すテスト用クライアント
  class FakeClient
    attr_reader :requests

    def initialize(responses)
      @responses = responses
      @requests = []
    end

    def get(path, **_params)
      @requests << path
      @responses.fetch(path) { raise PokeApi::Client::Error, "Not found: #{path}" }
    end
  end

  BASE = "https://pokeapi.co/api/v2".freeze

  def pokemon_payload(id:, name:, species_id:, is_default:, form_id:, types:, stats:)
    {
      "id" => id,
      "name" => name,
      "is_default" => is_default,
      "species" => { "name" => "raichu", "url" => "#{BASE}/pokemon-species/#{species_id}/" },
      "forms" => [ { "name" => name, "url" => "#{BASE}/pokemon-form/#{form_id}/" } ],
      "types" => types.each_with_index.map { |t, i| { "slot" => i + 1, "type" => { "name" => t } } },
      "abilities" => [ { "slot" => 1, "ability" => { "name" => "static" } } ],
      "stats" => %w[hp attack defense special-attack special-defense speed].zip(stats).map do |stat, value|
        { "base_stat" => value, "stat" => { "name" => stat } }
      end,
      "sprites" => {
        "front_default" => "https://example.com/#{id}.png",
        "other" => { "official-artwork" => { "front_default" => "https://example.com/art/#{id}.png" } }
      }
    }
  end

  setup do
    Pokemon.delete_all

    @client = FakeClient.new(
      "pokemon" => { "results" => [
        { "name" => "raichu", "url" => "#{BASE}/pokemon/26/" },
        { "name" => "raichu-alola", "url" => "#{BASE}/pokemon/10100/" },
        { "name" => "broken", "url" => "#{BASE}/pokemon/99999/" }
      ] },
      "#{BASE}/pokemon/26/" => pokemon_payload(id: 26, name: "raichu", species_id: 26, is_default: true,
                                               form_id: 26, types: %w[electric], stats: [ 60, 90, 55, 90, 80, 110 ]),
      "#{BASE}/pokemon/10100/" => pokemon_payload(id: 10100, name: "raichu-alola", species_id: 26, is_default: false,
                                                  form_id: 10202, types: %w[electric psychic], stats: [ 60, 85, 50, 95, 85, 110 ]),
      "#{BASE}/pokemon-species/26/" => { "names" => [
        { "name" => "Raichu", "language" => { "name" => "en" } },
        { "name" => "ライチュウ", "language" => { "name" => "ja-hrkt" } }
      ] },
      "#{BASE}/pokemon-form/10202/" => { "form_names" => [
        { "name" => "アローラのすがた", "language" => { "name" => "ja-hrkt" } }
      ] }
    )
  end

  test "ポケモンを取り込み、失敗したものはスキップする" do
    result = PokeApi::Importer.new(client: @client, logger: Logger.new(nil)).call

    assert_equal({ imported: 2, failed: [ "broken" ] }, result)

    alola = Pokemon.find_by!(pokeapi_id: 10100)
    assert_equal "ライチュウ", alola.name_ja
    assert_equal "アローラのすがた", alola.form_name_ja
    assert_equal %w[electric psychic], alola.types
    assert_equal 95, alola.special_attack
    assert_equal "https://example.com/art/10100.png", alola.artwork_url

    assert_nil Pokemon.find_by!(pokeapi_id: 26).form_name_ja
  end

  test "同じ種族の日本語名は一度だけ取得し、通常フォームのフォーム名は取得しない" do
    PokeApi::Importer.new(client: @client, logger: Logger.new(nil)).call

    assert_equal 1, @client.requests.count("#{BASE}/pokemon-species/26/")
    assert_not_includes @client.requests, "#{BASE}/pokemon-form/26/"
  end

  test "再実行しても重複せず更新される" do
    importer = PokeApi::Importer.new(client: @client, logger: Logger.new(nil))
    importer.call
    importer.call

    assert_equal 2, Pokemon.count
  end
end
