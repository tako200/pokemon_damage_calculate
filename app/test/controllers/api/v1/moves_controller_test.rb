require "test_helper"

class Api::V1::MovesControllerTest < ActionDispatch::IntegrationTest
  test "index は全技から検索し、技の情報を返す" do
    get api_v1_moves_path, params: { q: "じしん" }

    assert_response :success
    assert_equal [ {
      "id" => 89, "name" => "earthquake", "name_ja" => "じしん", "type" => "ground",
      "damage_class" => "physical", "power" => 100, "accuracy" => 100, "pp" => 10, "priority" => 0,
      "target" => "all-other-pokemon", "is_spread" => true, "min_hits" => nil, "max_hits" => nil
    } ], response.parsed_body["moves"]
  end

  test "index は省略時に変化技を返さない" do
    get api_v1_moves_path

    names = response.parsed_body["moves"].map { |m| m["name"] }
    assert_not_includes names, "swords-dance"
    assert_equal "earthquake", names.first
  end

  test "show は ID でも英語名でも取得できる" do
    get api_v1_move_path(541)
    assert_equal({ "min_hits" => 2, "max_hits" => 5 }, response.parsed_body.slice("min_hits", "max_hits"))

    get api_v1_move_path("tail-slap")
    assert_equal 541, response.parsed_body["id"]
  end

  test "show は存在しない場合 404 を返す" do
    get api_v1_move_path("splash-of-doom")

    assert_response :not_found
  end
end
