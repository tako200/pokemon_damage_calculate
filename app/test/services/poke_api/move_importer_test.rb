require "test_helper"

class PokeApi::MoveImporterTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(responses)
      @responses = responses
    end

    def get(path, **_params)
      @responses.fetch(path) { raise PokeApi::Client::Error, "Not found: #{path}" }
    end
  end

  BASE = "https://pokeapi.co/api/v2".freeze

  setup do
    @client = FakeClient.new(
      "move" => { "results" => [
        { "name" => "tail-slap", "url" => "#{BASE}/move/541/" },
        { "name" => "broken", "url" => "#{BASE}/move/99999/" }
      ] },
      "#{BASE}/move/541/" => {
        "id" => 541,
        "name" => "tail-slap",
        "names" => [ { "name" => "スイープビンタ", "language" => { "name" => "ja-hrkt" } } ],
        "type" => { "name" => "normal" },
        "damage_class" => { "name" => "physical" },
        "power" => 25, "accuracy" => 85, "pp" => 10, "priority" => 0,
        "target" => { "name" => "selected-pokemon" },
        "meta" => { "min_hits" => 2, "max_hits" => 5 }
      }
    )
  end

  test "技を取り込み、失敗したものはスキップする" do
    Move.where(pokeapi_id: 541).delete_all

    result = PokeApi::MoveImporter.new(client: @client, logger: Logger.new(nil)).call

    assert_equal({ imported: 1, failed: [ "broken" ] }, result)
    move = Move.find_by!(pokeapi_id: 541)
    assert_equal "スイープビンタ", move.name_ja
    assert_equal "physical", move.damage_class
    assert_equal [ 2, 5 ], [ move.min_hits, move.max_hits ]
  end

  test "再実行しても重複しない" do
    importer = PokeApi::MoveImporter.new(client: @client, logger: Logger.new(nil))

    assert_no_difference -> { Move.count } do
      importer.call
      importer.call
    end
  end
end
