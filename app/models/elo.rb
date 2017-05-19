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
    else
      return "#{@note}"
    end
  end

  def date
    if (true == self.game.is_a?(Game))
      return self.game.game_date
    else
      return @date
    end
  end

  def self.process_game(franchises, game)
    home_franchise = franchises[game.home_team.franchise]
    away_franchise = franchises[game.away_team.franchise]
    elo_change = Elo.home_elo_change(game.home_score,
                                     home_franchise.elo.value,
                                     game.away_score,
                                     away_franchise.elo.value,
                                     game.overtime?,
                                     game.playoff?
                                    )
    home_franchise.add(Elo.new(:value => (home_franchise.elo.value + elo_change), :game => game))
    away_franchise.add(Elo.new(:value => (away_franchise.elo.value - elo_change), :game => game))

    return franchises
  end

  def self.initialize_new_season(season, franchises)
    season.franchises.each do |franchise_name|
      value = nil
      note  = ""

      if (false == franchises.include?(franchise_name))
        franchises[franchise_name] = Franchise.new(franchise_name)
        note = "New franchise"
      else
        value = Elo.new_season_adjustment(franchises[franchise_name].elo.value)
        note = "Start #{season.name}"
      end

      franchises[franchise_name].add(Elo.new(:value => value, :date => season.start_date.yesterday, :note => note))
    end

    return franchises
  end

  def self.create_entry(results, franchises, request_date)
    entry = {
      :date => request_date
    }

    franchises.values.each do |franchise|
      entry[franchise.name] = franchise.to_gdata(request_date)
    end

    results << entry

    return results
  end

  def self.process(params = {:gdata => false})
    franchises = {}
    results    = []
    seasons    = Season.all.sort_by { |season| season.start_date }

    seasons.each do |season|
      games = season.games.order({:game_date => :asc})

      if (false == season.empty?)
        Elo.initialize_new_season(season, franchises)
        Elo.create_entry(results, franchises, season.start_date.yesterday)

        processing_date = games.first.game_date

        games.each do |game|
          if (processing_date != game.game_date)
            Elo.create_entry(results, franchises, processing_date)
            processing_date = game.game_date
          end

          Elo.process_game(franchises, game)
        end

        Elo.create_entry(results, franchises, processing_date)
      end
    end

    if (true == params[:gdata])
      return results
    else
      return franchises
    end
  end

  def self.gdata
    return Elo.process(:gdata => true)
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
end
