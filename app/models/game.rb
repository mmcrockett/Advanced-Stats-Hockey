class Game < ActiveRecord::Base
  belongs_to :home_team, :class_name => 'Team', :foreign_key => "home_team_id"
  belongs_to :away_team, :class_name => 'Team', :foreign_key => "away_team_id"

  before_save :check_championship

  private
  def check_championship
    if (true == self.championship?)
      self.playoff = true
    end
  end
end
