class ElosController < ApplicationController
  def graph
    @data = Elo.gdata
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
