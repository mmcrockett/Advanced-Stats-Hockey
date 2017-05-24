require 'test_helper'

class FranchiseTest < ActiveSupport::TestCase
  test "are equal if name is equal" do
    assert(Franchise.new("X"), Franchise.new("X"))
    assert(Franchise.new("X"), "X")
    assert([Franchise.new("X")].include?("X"))
  end

  test "compare fails if not string or franchise" do
    err = assert_raises { Franchise.new([]) == Franchise.new("X") }
    assert_match(/Name in franchise is not a string./, err.message)
  end

  test "add stores an elo value and sets franchise to name" do
    f = Franchise.new("franchiseA")

    f.add(Elo.new(:date => Date.today)).add(Elo.new(:date => Date.today.tomorrow))
    assert_equal(2, f.elos.size)

    f.elos.each do |elo|
      assert_equal("franchiseA", elo.franchise)
    end
  end

  test "add throws if class isn't elo" do
    f = Franchise.new("franchiseA")

    err = assert_raises { f.add(9) }
    assert_match(/Not an Elo class '/, err.message)
  end

  test "add throws if date is earlier" do
    f = Franchise.new("franchiseA")

    err = assert_raises { f.add(Elo.new(:date => Date.today)).add(Elo.new(:date => Date.today.yesterday)) }
    assert_match(/Expectation is that elos are loaded in order/, err.message)
  end

  test "last value returns last elo value" do
    f = Franchise.new("franchiseA")

    f.add(Elo.new({:date => Date.today.yesterday.yesterday}))
    assert_equal(1500, f.elo.value)

    f.add(Elo.new(:value => 1308, :date => Date.today))
    assert_equal(1308, f.elo.value)

    assert_equal(1500, f.elo(Date.today.yesterday.yesterday).value)
    assert_equal(1308, f.elo(Date.today).value)

    assert_equal(1500, f.elo(Date.today.yesterday).value)
    assert_equal(1308, f.elo(Date.today.tomorrow).value)
    assert_equal(nil, f.elo(Date.today.yesterday.yesterday.yesterday))
  end

  test "disbanded franchise returns nil elo after disband date" do
    f = Franchise.new("franchiseA")

    f.add(Elo.new(:date => Date.today.yesterday.yesterday))
    f.add(Elo.new(:value => 1308, :date => Date.today.yesterday))
    f.disbanded_date = Date.today.yesterday
    assert_equal(1500, f.elo(Date.today.yesterday.yesterday).value)
    assert_equal(nil, f.elo(Date.today.yesterday))
    assert_equal(nil, f.elo(Date.today))
    assert_equal(nil, f.elo(Date.today.tomorrow))
  end

  test "creates a google chart entry" do
    f = Franchise.new("franchiseA")
    g = games(:game_0)
    d = g.game_date.yesterday.yesterday

    f.add(Elo.new(:date => d))
    f.add(Elo.new(:value => 1308, :game => g))

    assert_equal({:elo => 1500, :tooltip => 1500.to_s, :annotation => nil}, f.to_gdata(d))
    assert_equal({:elo => 1500, :tooltip => 1500.to_s, :annotation => nil}, f.to_gdata(g.game_date.yesterday))
    assert_equal({:elo => 1308, :tooltip => "#{g.tooltip}", :annotation => g.annotation("franchiseA")}, f.to_gdata(g.game_date))
  end
end
