class ElosController < ApplicationController
  def graph
    if (true == request.format.json?)
      chart_data = Elo.process

      @data   = chart_data.gdata
      @labels = chart_data.gdata_labels
    end
  end

  def money_lines
    @money_lines = MoneyLine.get
  end

  def index
    @elos = []

    Elo.process.franchises.each do |franchise|
      @elos << franchise.elos
    end

    @elos.flatten!
    @elos.sort_by! { |elo| elo.date }
  end
end
