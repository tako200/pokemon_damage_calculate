require "test_helper"

class Api::V1::Pokemons::MovesControllerTest < ActionDispatch::IntegrationTest
  test "index はそのポケモンが覚える攻撃技を威力の高い順に返す" do
    get api_v1_pokemon_moves_path(445)

    assert_response :success
    assert_equal %w[earthquake dragon-claw low-kick], response.parsed_body["moves"].map { |m| m["name"] }
  end

  test "index は覚えない技を返さない" do
    get api_v1_pokemon_moves_path("garchomp"), params: { q: "ボルト" }

    assert_response :success
    assert_empty response.parsed_body["moves"]
  end

  test "index は検索語・技の分類・タイプで絞り込める" do
    get api_v1_pokemon_moves_path("garchomp"), params: { q: "どらごん" }
    assert_equal [ "dragon-claw" ], response.parsed_body["moves"].map { |m| m["name"] }

    get api_v1_pokemon_moves_path("garchomp"), params: { damage_class: "status" }
    assert_equal [ "swords-dance" ], response.parsed_body["moves"].map { |m| m["name"] }

    get api_v1_pokemon_moves_path("garchomp"), params: { type: "ground" }
    assert_equal [ "earthquake" ], response.parsed_body["moves"].map { |m| m["name"] }
  end

  test "index は limit を指定したときだけ件数を絞る" do
    get api_v1_pokemon_moves_path("garchomp"), params: { limit: 1 }

    assert_equal [ "earthquake" ], response.parsed_body["moves"].map { |m| m["name"] }
  end

  test "技のデータが無いメガシンカは、通常の姿の技を返す" do
    get api_v1_pokemon_moves_path("garchomp-mega-z")

    assert_response :success
    assert_equal %w[earthquake dragon-claw low-kick], response.parsed_body["moves"].map { |m| m["name"] }
  end

  test "メガシンカ以外のフォームは、技のデータが無ければ空を返す" do
    get api_v1_pokemon_moves_path("raichu-alola")

    assert_response :success
    assert_empty response.parsed_body["moves"]
  end

  test "index は存在しないポケモンなら 404 を返す" do
    get api_v1_pokemon_moves_path("missingno")

    assert_response :not_found
  end
end
