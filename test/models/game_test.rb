require 'test_helper'

class GameTest < ActiveSupport::TestCase
  test "can reference teams" do
    g = games(:game_0)
    assert(g.home_team)
    assert(g.away_team)
    assert_equal("Team A", g.home_team.name)
    assert_equal("Team B", g.away_team.name)
  end

  test "defaults are correct" do
    g = games(:game_0)
    assert_not(g.playoff?)
  end
end
