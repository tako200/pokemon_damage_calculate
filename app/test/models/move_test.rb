require "test_helper"

class MoveTest < ActiveSupport::TestCase
  test "ひらがなの技名をカタカナで入力しても検索できる" do
    assert_equal [ "earthquake" ], Move.search("ジシン").pluck(:name)
  end

  test "カタカナの技名をひらがなで入力しても検索できる" do
    assert_equal [ "dragon-claw" ], Move.search("どらごん").pluck(:name)
  end

  test "英語名でも検索できる" do
    assert_equal [ "dragon-claw" ], Move.search("Dragon").pluck(:name)
  end

  test "with_damage_class は省略時に変化技を除く" do
    assert_not_includes Move.with_damage_class(nil).pluck(:name), "swords-dance"
    assert_equal [ "swords-dance" ], Move.with_damage_class("status").pluck(:name)
    assert_equal Move.count, Move.with_damage_class("all").count
    assert_equal [ "thunderbolt" ], Move.with_damage_class("special").pluck(:name)
  end

  test "with_type でタイプを絞り込める" do
    assert_equal [ "earthquake" ], Move.with_type("ground").pluck(:name)
    assert_equal Move.count, Move.with_type(nil).count
  end

  test "power_order は威力の高い順で、威力のない技は最後" do
    names = Move.where(name: %w[low-kick earthquake dragon-claw]).power_order.pluck(:name)
    assert_equal %w[earthquake dragon-claw low-kick], names
  end

  test "spread? は範囲技かどうかを返す" do
    assert moves(:earthquake).spread?
    assert_not moves(:dragon_claw).spread?
  end
end
