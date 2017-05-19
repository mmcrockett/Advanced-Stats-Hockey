require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  test "if franchise is null, set to team name" do
    t = Team.new({:name => 'BLaH De bLAH'})
    t.save
    t.reload
    assert_equal(t.franchise, t.name)
  end

  test "if franchise is set let it alone" do
    t = Team.new({:name => 'BLaH De bLAH', :franchise => "hello"})
    t.save
    t.reload
    assert_equal("hello", t.franchise)
  end

  test "save team name removes non alpha numeric characters" do
    t = Team.new({:name => "Mike's %AMAZIN99% Team"})
    t.save
    t.reload
    assert_equal("Mikes Amazin99 Team", t.name)
  end

  test "save team name trims" do
    t = Team.new({:name => "    Blah De Blah     "})
    t.save
    t.reload
    assert_equal("Blah De Blah", t.name)
  end


  test "save team name as titleized" do
    t = Team.new({:name => 'BLaH De bLAH'})
    t.save
    t.reload
    assert_equal("Blah De Blah", t.name)
  end


  test "can render a short name" do
    no_name       = Team.new()
    crazy_name    = Team.new(:name => '  BLaH De bLAH  ')
    no_space_name = Team.new(:name => 'Highlanders')

    assert_equal("", no_name.abbreviated)
    assert_equal("BDB", crazy_name.abbreviated)
    assert_equal("Hig", no_space_name.abbreviated)
  end

  test "can reference home and away games" do
    t = teams(:team_b)
    assert(t.home_games)
    assert(t.away_games)
    assert_equal(1, t.home_games.size)
    assert_equal(1, t.away_games.size)
    assert_equal(t.home_games + t.away_games, t.games)
  end
end
