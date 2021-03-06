class Team < ActiveRecord::Base
  belongs_to :season

  has_many :home_games, :class_name => 'Game', :foreign_key => "home_team_id"
  has_many :away_games, :class_name => 'Game', :foreign_key => "away_team_id"

  before_save :check_franchise

  def name=(name)
    super(name.strip.downcase.titleize.gsub(/[^0-9a-z ]/i, ''))
  end

  def check_franchise
    if (nil == self.franchise)
      self.franchise = self.name
    end

    return true
  end

  def games
    return self.home_games + self.away_games
  end

  def abbreviated
    if (nil == self.name)
      return ""
    else
      return self.name.abbreviated
    end
  end

  def self.lookup(raw_name, season)
    team_name = Team.new(:name => raw_name).name

    if (false == season.is_a?(Season))
      return Team.find_by(:name => team_name)
    else
      return season.teams.find_by(:name => team_name)
    end
  end

  def self.lookup_home(pp_game, season = nil)
    return Team.lookup(pp_game[PointhogParser::POINTHOG_HOME_COLUMN], season)
  end

  def self.lookup_away(pp_game, season = nil)
    return Team.lookup(pp_game[PointhogParser::POINTHOG_AWAY_COLUMN], season)
  end
end
