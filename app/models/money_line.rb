class MoneyLine
  attr_accessor :home_team, :away_team, :home_elo, :away_elo, :date

  def initialize(params = {})
    params = params.with_indifferent_access
    @home_team = params[:home_team]
    @away_team = params[:away_team]
    @home_elo  = params[:home_elo]
    @away_elo  = params[:away_elo]
    @date      = params[:date]
  end

  def home_line
    return MoneyLine.vigged_line(self.home_probability)
  end

  def away_line
    return MoneyLine.vigged_line(self.away_probability)
  end

  def away_probability
    return (1 - self.home_probability)
  end

  def home_probability
    return Elo.expected_home_probability(@home_elo, @away_elo)
  end

  def home_identifier
    return identifier(@home_team.name, @home_elo)
  end

  def away_identifier
    return identifier(@away_team.name, @away_elo)
  end

  def self.probability(moneyline)
    if (0 < moneyline)
      return (100.to_f/(100+moneyline))
    else
      return (-moneyline.to_f/(100-moneyline))
    end
  end

  def self.vigged_line(probability)
    ml = MoneyLine.money_line(probability)

    if (0 > ml)
      return (ml + (ml.abs % 10))
    else
      return ml.round(-1)
    end
  end

  def self.vig_percent(line0, line1)
    return ((1 - MoneyLine.probability(line0) - MoneyLine.probability(line1)) * 100)
  end

  def self.money_line(probability)
    if ((probability <= 0) || (probability >= 1))
      raise "Not sure what to do with probability >= 1 or <= 0 '#{probability}'."
    end

    if (probability >= 0.5)
      return (100.to_f/(1.to_f - (1.to_f/probability))).to_i
    else
      return ((100.to_f / probability) - 100.to_f).to_i
    end
  end

  def self.get
    money_lines   = []
    pending_games = []

    Season.where(:complete => false).each do |season|
      pp = PointhogParser.load_html(season.pointhog_url)
      pending_games += PointhogParser.new(PointhogParser.load_html(season.pointhog_url)).pending_games
    end

    if (false == pending_games.empty?)
      pending_games.sort_by { |game| game[PointhogParser::POINTHOG_DATE_COLUMN] }
      chosen_games = []
      chosen_dates = Set.new

      pending_games.each do |game|
        game_date = game[PointhogParser::POINTHOG_DATE_COLUMN]
        chosen_dates << game_date

        if (2 >= chosen_dates.size)
          chosen_games << game
        else
          break
        end
      end

      chart_data    = Elo.process

      chosen_games.each do |pending_game|
        home_team = Team.lookup_home(pending_game)
        away_team = Team.lookup_away(pending_game)

        if ((nil != home_team) && (nil != away_team))
          money_line = MoneyLine.new(
            :home_team => home_team,
            :away_team => away_team,
            :date => pending_game[PointhogParser::POINTHOG_DATE_COLUMN]
          )

          home_franchise = chart_data.franchise(money_line.home_team.franchise)
          away_franchise = chart_data.franchise(money_line.away_team.franchise)

          money_line.home_elo = home_franchise.elo.value
          money_line.away_elo = away_franchise.elo.value

          money_lines << money_line
        end
      end
    end

    return money_lines
  end

  private
  def identifier(name, elo)
    return "#{name} (#{elo})"
  end
end
