class Season < ActiveRecord::Base
  before_save :load_data

  def load_data
    if (true == self.parse?)
      #page = Nokogiri::HTML(open(self.pointhog_url))
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
end
