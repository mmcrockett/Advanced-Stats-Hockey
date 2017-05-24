class Franchise
  attr_accessor :name, :elos, :disbanded_date

  DEFAULT_GDATA = {
    :elo => nil,
    :tooltip => nil,
    :annotation => nil
  }

  def initialize(name)
    @name = name
    @elos = []
    @disbanded_date = nil
  end

  def ==(other_franchise)
    if (true == other_franchise.is_a?(Franchise))
      if ((true == other_franchise.name.is_a?(String)) && (true == self.name.is_a?(String)))
        return (self.name == other_franchise.name)
      else
        raise "Name in franchise is not a string."
      end
    elsif (true == other_franchise.is_a?(String))
      return (self.name == other_franchise)
    else
      raise "Can only compare to other Franchises or String name '#{other_franchise.class}'."
    end
  end

  def add(elo)
    if (true == elo.is_a?(Elo))
      if ((false == @elos.empty?) && (@elos.first.date >= elo.date))
        raise "Expectation is that elos are loaded in order '#{@elos.first.date}' >= '#{elo.date}'."
      end

      elo.franchise = self.name
      @elos.unshift(elo)
    else
      raise "Not an Elo class '#{elo.class}'"
    end

    return self
  end

  def to_s
    elo   = self.elo
    value = -1

    if (nil != elo)
      value = elo.value
    end

    return "#{self.name}(#{value})"
  end

  def to_gdata(date)
    elo  = self.elo(date)
    data = {}.merge(DEFAULT_GDATA)

    if (nil != elo)
      data[:elo]     = elo.value

      if (true == elo.game.is_a?(Game))
        if (date == elo.date)
          data[:tooltip]    = elo.note
          data[:annotation] = elo.game.annotation(self.name)
        else
          data[:tooltip]    = "#{elo.value}"
        end
      else
        data[:tooltip] = elo.note
      end
    end

    return data
  end

  def disbanded?(requested_date = Date.today)
    if (nil == disbanded_date)
      return false
    else
      return (disbanded_date <= requested_date)
    end
  end

  def elo(requested_date = nil)
    if (nil == requested_date)
      elo = @elos.first
    elsif (true == self.disbanded?(requested_date))
      elo = nil
    else
      elo = @elos.bsearch { |elo| elo.date <= requested_date }
    end

    return elo
  end
end
