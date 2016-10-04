require 'test_helper'

class EloTest < ActiveSupport::TestCase
  test "elo sanity checks" do
    # Underdog tie should get some points
    assert(0 < Elo.home_elo_change(3, 1400, 2, 1600, true, false))

    # Playoff is worth more than regular
    regular = Elo.home_elo_change(3, 1500, 2, 1500, false, false)
    playoff = Elo.home_elo_change(3, 1500, 2, 1500, false, true)
    assert(playoff.abs > regular.abs)

    # Underdog win is worth more than favorite win
    udog = Elo.home_elo_change(3, 1400, 2, 1600, false, false)
    fav  = Elo.home_elo_change(2, 1400, 3, 1600, false, false)
    assert(udog.abs > fav.abs)
    assert(udog > 0)
    assert(fav < 0)

    # The more underdog the win the bigger the reward
    game0 = Elo.home_elo_change(3, 1450, 2, 1550, false, false)
    game1 = Elo.home_elo_change(3, 1400, 2, 1600, false, false)
    assert(game1 > game0)
    assert(game0 > 0)
    assert(game1 > 0)

    # The more favored the win the lesser the reward
    game0 = Elo.home_elo_change(3, 1550, 2, 1450, false, false)
    game1 = Elo.home_elo_change(3, 1600, 2, 1400, false, false)
    assert(game0 > game1)
    assert(game0 > 0)
    assert(game1 > 0)

    # The bigger the margin of victory, the more rewards, but less so for more favored
    game0 = Elo.home_elo_change(6, 1500, 2, 1500, false, false)
    game2 = Elo.home_elo_change(6, 1600, 2, 1400, false, false)
    game1 = Elo.home_elo_change(3, 1500, 2, 1500, false, false)
    assert(game0 > game1)
    assert(game0 > game2)
    assert(game0 > 0)
    assert(game1 > 0)
    assert(game2 > 0)

    # Test the limits of elo change
    assert(5 > Elo.home_elo_change(8, 1750, 0, 1250, false, false))
    assert(15 < Elo.home_elo_change(8, 1250, 0, 1750, false, false))
  end

  test "elo for tie between even teams is 0" do
    assert_equal(0, Elo.home_elo_change(3, 1500, 2, 1500, true, false))
  end

  test "elo is symmetrical" do
    10.times.each do |score|
      home_varies_elo = Elo.home_elo_change(score, 1500, 5, 1500, false, false)
      away_varies_elo = Elo.home_elo_change(5, 1500, score, 1500, false, false)
      assert_equal(home_varies_elo.abs, away_varies_elo.abs)

      if (score > 5)
        assert(home_varies_elo > 0)
        assert(away_varies_elo < 0)
      elsif (score < 5)
        assert(home_varies_elo < 0)
        assert(away_varies_elo > 0)
      else
        assert_equal(0, away_varies_elo)
      end
    end
  end

  test "margin of victory multiplier works" do
    away_score  = 5
    away_elo    = Elo::DEFAULT_STARTING_ELO
    elo_margins = [-70, -35, 0, 35, 70]
    expected_margins = {
      -5 => [1.81,1.86,1.90,1.95,1.99],
      -4 => [1.63,1.69,1.74,1.79,1.84],
      -3 => [1.42,1.49,1.55,1.61,1.67],
      -2 => [1.14,1.23,1.31,1.39,1.46],
      -1 => [1.00,1.00,1.00,1.10,1.20],
       0 => [1.00,1.00,1.00,1.00,1.00],
       1 => [1.20,1.10,1.00,1.00,1.00],
       2 => [1.46,1.39,1.31,1.23,1.14],
       3 => [1.67,1.61,1.55,1.49,1.42],
       4 => [1.84,1.79,1.74,1.69,1.63],
       5 => [1.99,1.95,1.90,1.86,1.81]
    }

    10.times.each do |home_score|
      elo_margins.each_with_index do |elo_margin,i|
        home_elo = Elo::DEFAULT_STARTING_ELO + elo_margin
        expected_margin = expected_margins[home_score - away_score][i]
        calculated_margin = Elo.margin_of_victory_multiplier(home_score, home_elo, away_score, away_elo).round(2)

        assert_equal(expected_margin, calculated_margin.to_f, "#{home_score}:#{home_elo}")
      end
    end

    assert(3 > Elo.margin_of_victory_multiplier(8, 1250, 0, 1750))
  end

  test "new season adjusts towards the mean" do
    default_elo = Elo::DEFAULT_STARTING_ELO

    assert_equal(default_elo, Elo.new_season_adjustment(default_elo))
    assert_equal(default_elo + 100 - 33, Elo.new_season_adjustment(default_elo + 100))
    assert_equal(default_elo - 100 + 33, Elo.new_season_adjustment(default_elo - 100))

    100.times.each do |i|
      a_elo = default_elo - i
      b_elo = default_elo + i

      new_season_total_elo = Elo.new_season_adjustment(a_elo) + Elo.new_season_adjustment(b_elo)

      assert_equal(default_elo * 2, new_season_total_elo)
    end
  end

  test "probability model is correct" do
    assert(1 > Elo.expected_home_probability(500, 2500))
    assert(1 > Elo.expected_home_probability(2500, 500))
    assert_equal(0.5, Elo.expected_home_probability(1500, 1500))
    assert_equal(0.64, Elo.expected_home_probability(1550, 1450).round(2))
    assert_equal(0.76, Elo.expected_home_probability(1600, 1400).round(2))
    assert_equal(1-0.64, Elo.expected_home_probability(1450, 1550).round(2))
    assert_equal(1-0.76, Elo.expected_home_probability(1400, 1600).round(2))
  end
end
