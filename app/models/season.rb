class Season < ActiveRecord::Base
  attr_accessible :name, :pointhog, :loaded
  has_many :teams

  def valid_pointhog?(pointhog_url)
    if (nil == self.pointhog)
      return false
    elsif (self.pointhog != pointhog_url)
      return false
    end

    return true
  end
end
