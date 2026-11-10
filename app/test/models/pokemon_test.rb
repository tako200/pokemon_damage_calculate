require "test_helper"

class PokemonTest < ActiveSupport::TestCase
  test "カタカナの部分一致で検索できる" do
    assert_equal %w[raichu raichu-alola], Pokemon.search("チュウ").where(species_id: 26).dex_order.pluck(:name)
    assert_includes Pokemon.search("ピカ").pluck(:name), "pikachu"
  end

  test "ひらがなでもカタカナ名にヒットする" do
    assert_equal %w[garchomp garchomp-mega-z], Pokemon.search("がぶ").dex_order.pluck(:name)
  end

  test "フォーム名で検索できる" do
    assert_equal [ "raichu-alola" ], Pokemon.search("アローラ").pluck(:name)
  end

  test "英語名で大文字小文字を区別せず検索できる" do
    assert_equal %w[garchomp garchomp-mega-z], Pokemon.search("GARCH").dex_order.pluck(:name)
  end

  test "数字は図鑑番号として検索する" do
    assert_equal %w[raichu raichu-alola], Pokemon.search("26").dex_order.pluck(:name)
  end

  test "LIKE のワイルドカードはエスケープされる" do
    assert_empty Pokemon.search("%")
  end

  test "空のクエリは全件を返す" do
    assert_equal Pokemon.count, Pokemon.search(" ").count
  end

  test "display_name はフォーム名を含む" do
    assert_equal "ライチュウ（アローラのすがた）", pokemons(:raichu_alola).display_name
    assert_equal "ライチュウ", pokemons(:raichu).display_name
  end

  test "mega? はメガシンカのフォームだけを判定する" do
    assert pokemons(:garchomp_mega_z).mega?
    assert Pokemon.new(name: "charizard-mega-x").mega?
    assert Pokemon.new(name: "garchomp-mega").mega?
    assert_not pokemons(:garchomp).mega?
    assert_not Pokemon.new(name: "meganium").mega?
  end
end
