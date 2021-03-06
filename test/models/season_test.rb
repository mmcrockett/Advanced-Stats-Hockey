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

  test "start date is the earliest game date or today if no games" do
    season = seasons(:complete)
    empty  = seasons(:empty)

    assert_equal(games(:game_1).game_date, season.start_date)
    assert_equal(Date.today, empty.start_date)
  end

  test "franchises returns a list of all franchises for the season" do
    season = seasons(:complete)

    assert_equal(Set.new(["Team A", "Team B", "Team C"]), Set.new(season.franchises))
    assert_equal(["Team C"], seasons(:complete_2).franchises)
  end

  test "season is empty if no games exist" do
    assert(false == seasons(:complete).empty?)
    assert(true == seasons(:empty).empty?)
  end

  test "finished season causes us to be marked complete and marks last games as playoff" do
    season = Season.new({:name => 'test', :pointhog_url => SAMPLE_COMPLETED_SEASON_SCHEDULE_URL})
    season.save!

    assert_equal(true, season.complete?)

    season.games.each do |g|
      playoff_dates = []
      
      ["08/23/16 9:00 PM","08/23/16 10:15 PM","08/25/16 7:45 PM","08/27/16 5:45 PM","09/01/16 9:00 PM"].each do |playoff_date_str|
        playoff_dates << PointhogParser.parse_datetime(playoff_date_str)
      end

      if (true == playoff_dates.include?(g.game_date))
        assert(g.playoff?)

        if (playoff_dates.last == g.game_date)
          assert(g.championship?)
        end
      else
        assert(false == g.championship?)
        assert(false == g.playoff?)
      end
    end
  end

  test "has a shortened name" do
    season1 = Season.new(:name => "Spring 2017")
    season2 = Season.new(:name => "Fall/Winter 16")
    season3 = Season.new(:name => "Summer 2016")

    assert_equal("Spring17", season1.short_name)
    assert_equal("Fall16", season2.short_name)
    assert_equal("Summer16", season3.short_name)
  end
end
