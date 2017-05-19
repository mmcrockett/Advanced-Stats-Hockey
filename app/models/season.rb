require 'open-uri'

class Season < ActiveRecord::Base
  has_many :teams

  after_save :load_data
  validate :season_url

  SEASON_URL_IDENTIFIER = "Season"

  def load_data
    if (true == self.parse?)
      teams = {}

      pp = PointhogParser.new(PointhogParser.load_html(self.pointhog_url))

      pp.teams.each do |team_name|
        add_team(team_name)
      end

      pp.games.each do |game|
        home_team_name = Team.new({:name => game[PointhogParser::POINTHOG_HOME_COLUMN]}).name
        away_team_name = Team.new({:name => game[PointhogParser::POINTHOG_AWAY_COLUMN]}).name
        ruby_game_date = game[PointhogParser::POINTHOG_DATE_COLUMN]

        if (false == self.teams.find_by({:name => home_team_name}).home_games.exists?({:game_date => ruby_game_date}))
          g = Game.new
          g.home_team     = self.teams.find_by({:name => home_team_name})
          g.away_team     = self.teams.find_by({:name => away_team_name})
          g.home_score    = game[PointhogParser::HOME_SCORE_KEY]
          g.away_score    = game[PointhogParser::AWAY_SCORE_KEY]
          g.overtime      = game[PointhogParser::SHOOTOUT_KEY]
          g.game_date     = game[PointhogParser::POINTHOG_DATE_COLUMN]
          g.save!
        end
      end

      if (self.complete != pp.season_complete?)
        self.complete = pp.season_complete?
        self.save!
      end

      self.reload
    end
  end

  def start_date
    if (true == self.empty?)
      return Date.today
    else
      return self.games.select(:game_date).minimum(:game_date)
    end
  end

  def franchises
    return self.teams.select(:franchise).distinct.pluck(:franchise)
  end

  def empty?
    return self.games.empty?
  end

  def games
    return Game.where(:home_team_id => self.teams)
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
    team = Team.new({:name => team_name})

    if (false == self.teams.exists?({:name => team.name}))
      self.teams << team
    end
  end

  def season_url
    if ((nil != self.pointhog_url) && (true == self.pointhog_url.include?(SEASON_URL_IDENTIFIER)))
      page = Nokogiri::HTML(open(self.pointhog_url))

      if ((nil == self.name) || (true == self.name.empty?))
        self.name = page.css('span[id*=ContentMain_ContentHeaderAndLogo1_ContentHeaderLabelTitle]').first.text.strip()
      end

      new_url = page.css("a[href*=#{PointhogParser::DIVISION_SCHEDULE_URL_IDENTIFIER}]").css("a[title*=B1]").first.attributes['href'].text

      if (nil == new_url)
        errors.add(:pointhog_url, "Couldn't parse season url correctly.")
        return false
      else
        Rails.logger.info("Detected season url changing url from '#{self.pointhog_url}' to '#{new_url}'.")
        self.pointhog_url = new_url
      end
    end

    return true
  end
end
