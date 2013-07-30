class Team < ActiveRecord::Base
  attr_accessible :games, :goals_allowed, :goals_scored, :name, :points
  belongs_to :season
end
