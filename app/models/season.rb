require 'open-uri'

class Season < ActiveRecord::Base
  has_many :teams

  after_save  :load_data

  def load_data
    if (true == self.parse?)
      teams = {}
      page  = Nokogiri::HTML(open(self.pointhog_url))

      pp = PointhogParser.new(page)

      pp.teams.each do |team_name|
        add_team(team_name)
      end

      pp.games.each do |game|
        home_team_name = game[PointhogParser::POINTHOG_HOME_COLUMN]
        away_team_name = game[PointhogParser::POINTHOG_AWAY_COLUMN]
        ruby_game_date = game[PointhogParser::POINTHOG_DATE_COLUMN]

        if (false == self.teams.find_by({:name => home_team_name}).home_games.exists?({:game_date => ruby_game_date}))
          g = Game.new
          g.home_team     = self.teams.find_by({:name => home_team_name})
          g.away_team     = self.teams.find_by({:name => away_team_name})
          g.home_score    = game[PointhogParser::HOME_SCORE_KEY]
          g.away_score    = game[PointhogParser::AWAY_SCORE_KEY]
          g.overtime      = game[PointhogParser::SHOOTOUT_KEY]
          g.game_date     = game[PointhogParser::POINTHOG_DATE_COLUMN]
          g.elo_processed = false
          g.save!
        end
      end

      if (self.complete != pp.season_complete?)
        self.complete = pp.season_complete?
        self.save!
      end

      self.reload
      self.process_elo
    end
  end

  def games
    return Game.where(:home_team_id => self.teams)
  end

  def process_elo
    self.games.where({:elo_processed => false}).each do |g|
      if ((true == g.home_team.elos.exists?({:sample_date => g.game_date})) || (true == g.away_team.elos.exists?({:sample_date => g.game_date})))
        raise "!ERROR: Seems game might have been processed already '#{g.id}' '#{g.game_date}'."
      end

      elo_change = Elo.home_elo_change(g.home_score, g.home_team.elo, g.away_score, g.away_team.elo, g.overtime?, g.playoff?)

      Season.transaction do |t|
        g.home_team.elos << Elo.new({:sample_date => g.game_date, :value => (g.home_team.elo + elo_change)})
        g.away_team.elos << Elo.new({:sample_date => g.game_date, :value => (g.away_team.elo - elo_change)})
        g.elo_processed = true
        g.save!
      end
    end
  end

  def parse?
    if (false == self.complete?)
      if (true == self.pointhog_url.is_a?(String))
        if ((Time.now.yesterday > self.updated_at) || (true == self.pointhog_url_changed?))
          return true
        end
      end
    end

    return false
  end

  private
  def add_team(team_name)
    if (false == self.teams.exists?({:name => team_name}))
      self.teams << Team.new({:name => team_name})
    end
  end
end
