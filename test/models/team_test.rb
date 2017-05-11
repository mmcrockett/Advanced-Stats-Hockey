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
    crazy_name    = Team.new({:name => '  BLaH De bLAH  '})
    no_space_name = Team.new({:name => 'Highlanders'})

    assert_equal("", no_name.short_name)
    assert_equal("BDB", crazy_name.short_name)
    assert_equal("Hig", no_space_name.short_name)
  end

  test "can reference home and away games" do
    t = teams(:team_b)
    assert(t.home_games)
    assert(t.away_games)
    assert_equal(1, t.home_games.size)
    assert_equal(1, t.away_games.size)
    assert_equal(t.home_games + t.away_games, t.games)
  end

  test "can reference latest elo and get elo by date" do
    t = teams(:team_c)
    assert_equal(10, t.elo)
    assert_equal(8, t.elo(Date.new(2016,10,11)))
    assert_equal(12, t.elo(Date.new(2016,10,01)))
    assert_equal(Elo::DEFAULT_STARTING_ELO, t.elo(Date.new(2015,1,1)))
  end

  test "elo is default value if no previous elo is found" do
    t = teams(:team_a)
    assert_equal(Elo::DEFAULT_STARTING_ELO, t.elo)
    assert_equal(Elo::DEFAULT_STARTING_ELO, t.elo(Date.new(2016,10,11)))
  end

  test "elo is franchise value if no previous elo for current season and franchise has value in previous seasons" do
    team_d_s0 = teams(:team_d_s0)
    team_d_s1 = teams(:team_d_s1)
    franchise_c = teams(:team_c)
    assert_equal(franchise_c.elo, team_d_s0.elo)
    assert_equal(franchise_c.elo, team_d_s1.elo)

    team_d_s0.elos << Elo.new({:value => 6, :sample_date => Date.new(2016, 10, 20), :game_id => -1})
    assert_equal(team_d_s0.elo, team_d_s1.elo)
    assert_equal(6, team_d_s1.elo)
  end

  test "if any franchise changes, we have to reset all the elo data for the season." do
    team_y = teams(:team_y)
    team_x = teams(:team_x)
    team_c = teams(:team_c)

    assert_equal(10, team_c.elo)
    assert_equal(1, team_x.elo)
    assert_equal(2, team_y.elo)
    assert_equal(1, team_x.season.games.size)
    assert_equal(1, team_x.season.games.where({:elo_processed => true}).size)

    team_x.franchise = "TeamC"
    team_x.save!

    assert_equal(10, team_c.elo)
    assert_equal(team_c.elo, team_x.elo)
    assert_equal(Elo::DEFAULT_STARTING_ELO, team_y.elo)
    assert_equal(1, team_x.season.games.size)
    assert_equal(0, team_x.season.games.where({:elo_processed => true}).size)
  end
end
