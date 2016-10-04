class ElosController < ApplicationController
  before_action :set_elo, only: [:show, :edit, :update, :destroy]

  # GET /elos
  # GET /elos.json
  def index
    @elos = Elo.all
  end

  # GET /elos/1
  # GET /elos/1.json
  def show
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

  # DELETE /elos/1
  # DELETE /elos/1.json
  def destroy
    @elo.destroy
    respond_to do |format|
      format.html { redirect_to elos_url, notice: 'Elo was successfully destroyed.' }
      format.json { head :no_content }
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
