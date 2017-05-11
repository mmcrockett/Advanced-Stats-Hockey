class Elo < ActiveRecord::Base
  belongs_to :team
  belongs_to :game

  DEFAULT_STARTING_ELO = 1500
  K = BigDecimal.new(8)
  OUTCOME_VALUES = {:loss => 0.0, :tie => 0.5, :win => 1.0}
  IMPORTANCE = {:playoff => 1.5, :regular => 1.0}

  def self.home_elo_change(home_score, home_elo, away_score, away_elo, shootout, playoff)
    if ((home_score > 20) || (away_score > 20))
      raise "!ERROR: Values seem incorrect for score '#{home_score}' '#{away_score}'."
    end

    if ((home_elo < 500) || (away_elo < 500))
      raise "!ERROR: Values seem incorrect for elo '#{home_elo}' '#{away_elo}'."
    end

    outcome_value = nil
    importance    = IMPORTANCE[:regular]

    if (true == playoff)
      importance = IMPORTANCE[:playoff]
    end

    margin_multiplier = Elo.margin_of_victory_multiplier(home_score, home_elo, away_score, away_elo)
    expected_value = Elo.expected_home_probability(home_elo, away_elo)

    if ((true == shootout) || (home_score == away_score))
      outcome_value     = OUTCOME_VALUES[:tie]
      margin_multiplier = 1.0
    elsif (home_score > away_score)
      outcome_value = OUTCOME_VALUES[:win]
    else
      outcome_value = OUTCOME_VALUES[:loss]
    end

    elo_change = (K * importance * margin_multiplier * (outcome_value - expected_value))

    return elo_change.round
  end

  def self.expected_home_probability(home_elo, away_elo)
    exponent = (BigDecimal.new(home_elo) - BigDecimal.new(away_elo))/BigDecimal.new(400)
    probability = 1/(1 + 10**(-exponent))

    return probability
  end

  def self.margin_of_victory_multiplier(home_score, home_elo, away_score, away_elo)
    score_diff = BigDecimal.new(home_score - away_score)
    elo_diff   = BigDecimal.new(home_elo - away_elo)
    elo_adjust_mult = BigDecimal.new("0.85") / BigDecimal.new(100)
    elo_diff_adjusted = (elo_diff * elo_adjust_mult)

    result = Math.log((score_diff - elo_diff_adjusted).abs + BigDecimal.new("#{Math::E}") - 1)

    if (1 > result)
      return BigDecimal.new(1)
    end

    return result
  end

  def self.new_season_adjustment(ending_elo)
    new_elo = ((ending_elo - DEFAULT_STARTING_ELO).abs/3.0).floor

    if (ending_elo > DEFAULT_STARTING_ELO)
      return (ending_elo - new_elo)
    else
      return (ending_elo + new_elo)
    end
  end
end
