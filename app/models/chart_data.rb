class ChartData
  def initialize
    @data       = []
    @franchises = {}
    @game_dates = []
  end

  def add(season)
    if (true == season.is_a?(Season))
      if ((false == @data.empty?) && (self.season.start_date >= season.start_date))
        raise "Expectation is that seasons are loaded in order '#{self.season.start_date}' >= '#{season.start_date}'."
      end

      new_data = initialize_new_season(season)

      @data.unshift(new_data)
    else
      raise "Not an Season class '#{season.class}'"
    end

    return self
  end

  def process_game(game)
    home_franchise = @franchises[game.home_team.franchise]
    away_franchise = @franchises[game.away_team.franchise]
    elo_change = Elo.home_elo_change(game.home_score,
                                     home_franchise.elo.value,
                                     game.away_score,
                                     away_franchise.elo.value,
                                     game.overtime?,
                                     game.playoff?
                                    )
    home_franchise.add(Elo.new(:value => (home_franchise.elo.value + elo_change), :game => game))
    away_franchise.add(Elo.new(:value => (away_franchise.elo.value - elo_change), :game => game))

    if (false == @game_dates.include?(game.game_date))
      @game_dates << game.game_date
    end

    return self
  end

  def season
    return self.data[:season]
  end

  def franchises
    return @franchises.values
  end

  def gdata
    results = []

    @game_dates.each do |game_date|
      entry = {
        :date => game_date
      }

      @franchises.values.each do |franchise|
        entry[franchise.name] = franchise.to_gdata(game_date)
      end

      results << entry
    end

    return results
  end

  def data(requested_date = nil)
    if (nil == requested_date)
      return @data.first
    else
      return @data.bsearch { |data| data[:season].start_date <= requested_date }
    end
  end

  private
  def initialize_new_season(season)
    new_data = {
      :season => season
    }
    this_season_franchises = []

    season.franchises.each do |franchise_name|
      value = nil
      note  = ""

      if (false == @franchises.include?(franchise_name))
        note = "New franchise"
        @franchises[franchise_name] = Franchise.new(franchise_name)
      else
        value = Elo.new_season_adjustment(@franchises[franchise_name].elo.value)
        note = "Start #{season.name}"
      end

      new_data[franchise_name] = @franchises[franchise_name]
      this_season_franchises << @franchises[franchise_name]
      new_data[franchise_name].add(Elo.new(:value => value, :date => season.start_date.yesterday, :note => note))
    end

    Elo.recenter_mean(this_season_franchises)

    @franchises.values.each do |franchise|
      if ((false == franchise.disbanded?) && (false == this_season_franchises.include?(franchise)))
        last_elo = franchise.elo
        franchise.add(Elo.new(:date => last_elo.date.tomorrow, :value => last_elo.value, :note => "Franchise Disbanded (#{last_elo.value})"))
        franchise.disbanded_date = season.start_date.yesterday
      end
    end

    return new_data
  end
end
