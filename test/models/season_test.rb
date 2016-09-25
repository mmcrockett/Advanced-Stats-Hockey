require 'test_helper'

class SeasonTest < ActiveSupport::TestCase
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
    season = seasons(:not_complete)
    assert_not(season.parse?)
    season.pointhog_url = "blah"
    assert(season.parse?)
  end

  test "data is loaded for create" do
    season = seasons(:not_complete)
    assert_not(season.parse?)
    season.pointhog_url = "blah"
    assert(season.parse?)
  end
end
