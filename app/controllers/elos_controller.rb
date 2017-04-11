class ElosController < ApplicationController
  before_filter :elo_authorize, only: [:new, :edit, :update, :create]
  before_action :set_elo, only: [:show, :edit, :update]

  def graph
    @data = []
    elos  = Elo.all.order(:sample_date => :asc)

    if (false == elos.empty?)
      default_entry = {:date => nil}

      Team.select(:franchise).distinct.pluck(:franchise).each do |franchise|
        default_entry[franchise] = Elo::DEFAULT_STARTING_ELO
      end

      @data << default_entry.merge({:date => elos.first.sample_date.yesterday})

      elos.each do |elo|
        if (@data.last[:date] != elo.sample_date)
          new_entry = {}

          @data.last.each_pair do |k,v|
            new_entry[k] = v
          end

          @data << new_entry.merge({:date => elo.sample_date})
        end

        @data.last[elo.team.franchise] = elo.value
      end
    end
  end

  # GET /elos
  # GET /elos.json
  def index
    @elos = Elo.all
  end

  # GET /elos/new
  def new
    @elo = Elo.new
  end

  # GET /elos/1/edit
  def edit
  end

  # POST /elos
  # POST /elos.json
  def create
    @elo = Elo.new(elo_params)

    respond_to do |format|
      if @elo.save
        format.html { redirect_to @elo, notice: 'Elo was successfully created.' }
        format.json { render :show, status: :created, location: @elo }
      else
        format.html { render :new }
        format.json { render json: @elo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /elos/1
  # PATCH/PUT /elos/1.json
  def update
    respond_to do |format|
      if @elo.update(elo_params)
        format.html { redirect_to @elo, notice: 'Elo was successfully updated.' }
        format.json { render :show, status: :ok, location: @elo }
      else
        format.html { render :edit }
        format.json { render json: @elo.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_elo
      @elo = Elo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def elo_params
      params.require(:elo).permit(:team_id, :value, :sample_date)
    end
end
