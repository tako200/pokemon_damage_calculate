require "test_helper"

class Api::V1::PokemonsControllerTest < ActionDispatch::IntegrationTest
  test "index は検索結果を図鑑順で返す" do
    get api_v1_pokemons_path, params: { q: "らいちゅう" }

    assert_response :success
    body = response.parsed_body
    assert_equal %w[raichu raichu-alola], body["pokemons"].map { |p| p["name"] }

    alola = body["pokemons"].last
    assert_equal 10100, alola["id"]
    assert_equal "ライチュウ（アローラのすがた）", alola["display_name"]
    assert_equal %w[electric psychic], alola["types"]
    assert_equal({ "hp" => 60, "attack" => 85, "defense" => 50,
                   "special_attack" => 95, "special_defense" => 85, "speed" => 110 }, alola["base_stats"])
  end

  test "index は limit で件数を絞れる" do
    get api_v1_pokemons_path, params: { limit: 1 }

    assert_response :success
    assert_equal 1, response.parsed_body["pokemons"].size
  end

  test "show は ID で取得できる" do
    get api_v1_pokemon_path(10100)

    assert_response :success
    assert_equal "raichu-alola", response.parsed_body["name"]
  end

  test "show は英語名で取得できる" do
    get api_v1_pokemon_path("garchomp")

    assert_response :success
    assert_equal 445, response.parsed_body["id"]
  end

  test "show は存在しない場合 404 を返す" do
    get api_v1_pokemon_path("missingno")

    assert_response :not_found
    assert_equal({ "error" => "not_found" }, response.parsed_body)
  end
end
