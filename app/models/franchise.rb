class Franchise
  attr_accessor :name, :elos

  def initialize(name)
    @name = name
    @elos = []
  end

  def ==(other_franchise)
    if (true == other_franchise.is_a?(Franchise))
      if ((true == other_franchise.name.is_a?(String)) && (true == self.name.is_a?(String)))
        return (self.name == other_francise.name)
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

  def to_gdata(date)
    elo = self.elo(date)

    data = {:elo => elo.value}

    if ((date == elo.date) && (true == elo.game.is_a?(Game)))
      data[:tooltip]    = elo.game.tooltip
      data[:annotation] = elo.game.annotation(self.name)
    else
      data[:tooltip]    = elo.value
      data[:annotation] = nil
    end

    return data
  end

  def elo(requested_date = nil)
    if (nil == requested_date)
      elo = @elos.first
    else
      elo = @elos.bsearch { |elo| elo.date <= requested_date }
    end

    if (nil != elo)
      return elo
    else
      return nil
    end
  end
end
