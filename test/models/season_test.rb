require 'test_helper'
class SeasonTest < ActiveSupport::TestCase
  SAMPLE_COMPLETED_SEASON_SCHEDULE_URL = "test/fixtures/pointhog_schedule_previous_season#{PointhogParser::DIVISION_SCHEDULE_URL_IDENTIFIER}.html"
  SAMPLE_ONGOING_SEASON_SCHEDULE_URL = "test/fixtures/pointhog_schedule#{PointhogParser::DIVISION_SCHEDULE_URL_IDENTIFIER}.html"
  SAMPLE_ONGOING_SEASON_SCHEDULE_LATER_DATE_URL = "test/fixtures/pointhog_schedule_later_date#{PointhogParser::DIVISION_SCHEDULE_URL_IDENTIFIER}.html"
  SAMPLE_SEASON_URL = "test/fixtures/pointhog_Season.html"

  test "parse always false for complete" do
    season = seasons(:complete)
    assert_not(season.parse?)
  end

  test "parse always false if url is not a string" do
    season = Season.new
    assert_not(season.parse?)
  end

  test "parse true if url is string and been more than a day since update" do
    season = seasons(:not_complete)
    assert_not(season.parse?)
    season.updated_at = Time.now.yesterday.yesterday
    assert(season.parse?)
  end

  test "parse true if url is string and url has changed" do
    season = seasons(:not_complete)
    assert_not(season.parse?)
    season.pointhog_url = "blah"
    assert(season.parse?)
  end

  test "data is loaded for save" do
    season = seasons(:empty)
    assert_not(season.parse?)
    season.pointhog_url = SAMPLE_ONGOING_SEASON_SCHEDULE_URL
    assert(season.parse?)
    season.save!
    assert_equal(12, season.games.size)
    assert_equal(4, season.games.where({:overtime => true}).size)
    assert_equal(3, season.games.where({:game_date => Date.new(2016,9,9)}).size)
    assert_equal(2, season.games.where({:game_date => Date.new(2016,9,12)}).size)
    assert_equal(6, Team.where({:season => season}).size)
    assert_equal(false, season.complete?)
  end

  test "season urls ignore season name if name is set" do
    season = Season.new({:name => 'blahblah', :pointhog_url => SAMPLE_SEASON_URL})
    season.save!
    assert_equal("blahblah", season.name)
    assert_equal("http://www.PointHogSports.com/IceHockey/League/DivisionSchedule.aspx?7Mc2SbMG5aaSaf", season.pointhog_url)
  end

  test "season urls are converted to B1 division schedule urls and season name parsed" do
    season = Season.new({:pointhog_url => SAMPLE_SEASON_URL})
    season.save!
    assert_equal("Summer 2016", season.name)
    assert_equal("http://www.PointHogSports.com/IceHockey/League/DivisionSchedule.aspx?7Mc2SbMG5aaSaf", season.pointhog_url)
  end

  test "season urls are left alone if not containing #{Season::SEASON_URL_IDENTIFIER}" do
    season = Season.new({:name => 'blah', :pointhog_url => SAMPLE_COMPLETED_SEASON_SCHEDULE_URL})
    season.save!
    assert_equal("blah", season.name)
    assert_equal(SAMPLE_COMPLETED_SEASON_SCHEDULE_URL, season.pointhog_url)
  end

  test "data is loaded for create" do
    season = Season.new({:name => 'test', :pointhog_url => SAMPLE_ONGOING_SEASON_SCHEDULE_URL})
    season.save!
    assert_equal(12, season.games.size)
    assert_equal(4, season.games.where({:overtime => true}).size)
    assert_equal(6, Team.where({:season => season}).size)
    assert_equal(false, season.complete?)
  end

  test "data is not double entered" do
    season = Season.new({:name => 'test', :pointhog_url => SAMPLE_ONGOING_SEASON_SCHEDULE_URL})
    season.save!
    assert_equal(12, season.games.size)
    assert_equal(4, season.games.where({:overtime => true}).size)
    assert_equal(6, Team.where({:season => season}).size)
    season.pointhog_url = SAMPLE_ONGOING_SEASON_SCHEDULE_LATER_DATE_URL
    season.save!
    assert_equal(15, season.games.size)
    assert_equal(5, season.games.where({:overtime => true}).size)
    assert_equal(6, Team.where({:season => season}).size)
    assert_equal(false, season.complete?)
  end

  test "data can be loaded through season, team or game equally" do
    season = Season.new({:name => 'test', :pointhog_url => SAMPLE_COMPLETED_SEASON_SCHEDULE_URL})
    season.save!

    season.teams.each do |t|
      assert_equal(t.games.size, Game.where({:away_team_id => t}).size + Game.where({:home_team_id => t}).size)
      assert_equal(t.games.size, Team.find(t.id).games.size)
    end
  end

  test "finished season causes us to be marked complete" do
    season = Season.new({:name => 'test', :pointhog_url => SAMPLE_COMPLETED_SEASON_SCHEDULE_URL})
    season.save!

    assert_equal(true, season.complete?)
  end

  test "elo can be processed" do
    show_elo = false
    season = Season.new({:name => 'test', :pointhog_url => SAMPLE_COMPLETED_SEASON_SCHEDULE_URL})
    season.save!
    elo_total = 0
    elos_count = 0

    season.teams.each_with_index do |team,i|
      if (true == show_elo)
        team.elos.order({:sample_date => :asc}).each do |elo|
          puts "#{elo.sample_date}:#{elo.team.name}:#{elo.value}"
        end
      end

      elo_total += team.elo
      elos_count += team.elos.size
    end

    assert_equal(Elo::DEFAULT_STARTING_ELO * season.teams.size, elo_total)
    assert_equal(2*53, elos_count)
    assert_equal(53, season.games.where({:elo_processed => true}).count)
    assert_equal(0, season.games.where({:elo_processed => false}).count)

    if (true == show_elo)
      season.games.order({:game_date => :asc}).each do |game|
        game_info = ""
        pday = game.game_date.yesterday

        [game.home_team, game.away_team].each do |team|
          game_info += " #{team.name}:#{team.elo(pday)}:#{team.elo(game.game_date)}:#{team.elo(game.game_date) - team.elo(pday)}"
        end

        puts "#{game.game_date}:#{game.home_score}:#{game.away_score} #{game_info}"
      end
    end
  end
end
