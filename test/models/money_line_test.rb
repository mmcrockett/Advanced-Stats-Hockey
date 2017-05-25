require 'test_helper'

class MoneyLineTest < ActiveSupport::TestCase
  test "money lines are symmetrical with probability" do
    (2..10).each do |i|
      p = 1.to_f/i

      money_line   = MoneyLine.money_line(p)
      inverse_line = MoneyLine.money_line((1 - p))

      assert_equal(MoneyLine.probability(money_line).round(2), p.round(2))
      assert_equal(MoneyLine.probability(inverse_line).round(2), (1 - p).round(2))
    end
  end

  test "the vig takes some money" do
    ml = MoneyLine.new(:away_elo => 1488, :home_elo => 1557)

    assert_equal(-148, MoneyLine.money_line(ml.home_probability))
    assert_equal(148, MoneyLine.money_line(ml.away_probability))
    assert_equal(-140, ml.home_line)
    assert_equal(150, ml.away_line)
  end

  test "creates an array of next two dates of money lines" do
    money_lines = MoneyLine.get
    valid_dates = [Date.parse("27 Sep 2016"), Date.parse("30 Sep 2016")]

    assert_equal(6, money_lines.size)

    money_lines.each do |money_line|
      assert(true == valid_dates.include?(money_line.date), "Wrong date '#{money_line.date}'")
    end
  end
end
