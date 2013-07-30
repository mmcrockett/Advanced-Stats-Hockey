class Season < ActiveRecord::Base
  attr_accessible :name, :pointhog, :loaded
  has_many :teams
end
