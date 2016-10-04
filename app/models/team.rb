class Team < ActiveRecord::Base
  belongs_to :season

  has_many :home_games, :class_name => 'Game', :foreign_key => "home_team_id"
  has_many :away_games, :class_name => 'Game', :foreign_key => "away_team_id"
  has_many :elos

  before_update :franchise_reset
  before_save :titleize_name

  def titleize_name
    self.name = self.name.downcase.titleize

    if (nil == self.franchise)
      self.franchise = self.name
    end

    return true
  end

  def franchise_reset
    if (true == self.franchise_changed?)
      Team.transaction do |t|
        self.season.teams.each do |team|
          team.elos.each do |elo|
            elo.update({:ignore => true, :team_id => -1, :sample_date => Date.new(1980,1,1)})
          end
        end

        self.season.games.each do |game|
          game.update({:elo_processed => false})
        end
      end
    end

    return true
  end

  def games
    return self.home_games + self.away_games
  end

  def elo(requested_date = nil)
    requested_elo       = nil
    requested_elo_value = nil

    if (nil == requested_date)
      requested_elo = self.elos.order({:sample_date => :asc}).last
    else
      requested_elo = self.elos.where("sample_date <= ?", requested_date).order({:sample_date => :asc}).last
    end

    if (nil == requested_elo)
      previous_franchises = Team.where("franchise = ? AND season_id != ?", self.franchise, self.season_id)
      requested_elo = Elo.where({:team => previous_franchises}).order({:sample_date => :asc}).last
    end

    if (nil == requested_elo)
      requested_elo_value = Elo::DEFAULT_STARTING_ELO
    else
      requested_elo_value = requested_elo.value
    end

    return requested_elo_value
  end
end
