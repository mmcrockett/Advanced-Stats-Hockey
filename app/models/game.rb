class Game < ActiveRecord::Base
  belongs_to :home_team, :class_name => 'Team', :foreign_key => "home_team_id"
  belongs_to :away_team, :class_name => 'Team', :foreign_key => "away_team_id"

  before_save :check_championship

  def to_s
    return "#{self.winner.abbreviated} d. #{self.loser.abbreviated} #{self.winner_score}-#{self.loser_score}"
  end
  alias :tooltip :to_s

  def annotation(franchise_name)
    if (true == self.championship?)
      if (franchise_name == self.winner.franchise)
        return "#{self.winner.franchise.abbreviated} Champions"
      elsif (franchise_name == self.loser.franchise)
        return "#{self.loser.franchise.abbreviated} Finals Loss"
      end
    end

    return nil
  end

  def winner_score
    return outcome[:winner][:score]
  end

  def winner
    return outcome[:winner][:team]
  end

  def loser_score
    return outcome[:loser][:score]
  end

  def loser
    return outcome[:loser][:team]
  end

  def season
    return self.home_team.season
  end

  private
  def outcome
    winner = {
      :team  => self.away_team,
      :score => self.away_score
    }
    loser  = {
      :team  => self.home_team,
      :score => self.home_score
    }

    if (self.home_score > self.away_score)
      tmp    = loser 
      loser  = winner
      winner = tmp
    end

    return {:winner => winner, :loser => loser}
  end

  def check_championship
    if (true == self.championship?)
      self.playoff = true
    end
  end
end
