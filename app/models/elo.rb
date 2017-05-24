class Elo
  attr_accessor :value, :game, :franchise, :note

  DEFAULT_STARTING_ELO = 1500
  K = BigDecimal.new(8)
  OUTCOME_VALUES = {:loss => 0.0, :tie => 0.5, :win => 1.0}
  IMPORTANCE = {:playoff => 1.5, :regular => 1.0}

  def initialize(params = {})
    @value = params[:value] || DEFAULT_STARTING_ELO
    @game  = params[:game]  || nil
    @date  = params[:date]  || nil
    @note  = params[:note]  || ""
    @franchise = params[:franchise] || "Uninitialized"

    if ((nil == @game) && (nil == @date))
      raise "An elo without a game or date makes no sense. Provide one of them."
    end
  end

  def note
    if (true == self.game.is_a?(Game))
      return "#{game}"
    elsif ((nil != @note) && (false == @note.empty?))
      return "#{@note}"
    else
      return "#{self.value}"
    end
  end

  def date
    if (true == self.game.is_a?(Game))
      return self.game.game_date
    else
      return @date
    end
  end

  def self.process
    chart_data = ChartData.new
    seasons    = Season.all.sort_by { |season| season.start_date }

    seasons.each do |season|
      games = season.games.order({:game_date => :asc})

      if (false == season.empty?)
        chart_data.add(season)

        processing_date = games.first.game_date

        games.each do |game|
          if (processing_date != game.game_date)
            processing_date = game.game_date
          end

          chart_data.process_game(game)
        end
      end
    end

    return chart_data
  end

  def self.gdata
    return Elo.process.gdata
  end

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

  def self.recenter_mean(franchises)
    total_elo    = 0
    current_mean = Elo::DEFAULT_STARTING_ELO

    franchises.each do |franchise|
      total_elo += franchise.elo.value
    end

    current_mean = (total_elo/franchises.size)

    if ((current_mean - Elo::DEFAULT_STARTING_ELO).abs > 1)
      Rails.logger.info("Recentering required for '#{current_mean}' on '#{franchises * ':'}'.")

      franchises.each do |franchise|
        franchise.elo.value = ((franchise.elo.value - current_mean) + Elo::DEFAULT_STARTING_ELO).floor
      end

      Rails.logger.info("Recentering complete for '#{current_mean}' on '#{franchises * ':'}'.")
    end

    return franchises
  end
end
