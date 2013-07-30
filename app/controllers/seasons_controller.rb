require 'rubygems'
require 'nokogiri'
require 'open-uri'

class SeasonsController < ApplicationController
  # GET /seasons
  # GET /seasons.json
  def index
    @seasons = Season.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @seasons }
    end
  end

  # GET /seasons/1
  # GET /seasons/1.json
  def show
    @season = Season.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @season }
    end
  end

  # GET /seasons/new
  # GET /seasons/new.json
  def new
    @season = Season.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @season }
    end
  end

  # GET /seasons/1/edit
  def edit
    @season = Season.find(params[:id])
  end

  # POST /seasons
  # POST /seasons.json
  def create
    @season = Season.new(params[:season])

    respond_to do |format|
      if @season.save
        format.html { redirect_to @season, notice: 'Season was successfully created.' }
        format.json { render json: @season, status: :created, location: @season }
      else
        format.html { render action: "new" }
        format.json { render json: @season.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /seasons/1
  # PUT /seasons/1.json
  def update
    @season = Season.find(params[:id])

    if (false == @season.loaded?())
      page = Nokogiri::HTML(open(params[:pointhog]))
      page.css('tr th:first-child').each do |team_th|
        if ("Team" == team_th.text().strip)
          tr = team_th.parent.next
        end

        while (nil != tr)
          team = Team.new()
          team.name = tr.css('td')[0].text().strip
          team.season = @season
          team.games         = tr.css('td')[1].text()
          team.points        = tr.css('td')[6].text()
          team.goals_scored  = tr.css('td')[7].text()
          team.goals_allowed = tr.css('td')[8].text()
          team.save()
          tr = tr.next
        end
      end
    end

    params[:loaded] = true
    params[:season][:loaded] = true

    respond_to do |format|
      if @season.update_attributes(params[:season])
        format.html { redirect_to @season, notice: 'Season was successfully updated.' }
        format.json { render :json => @season }
      else
        format.html { render action: "edit" }
        format.json { render json: @season.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /seasons/1
  # DELETE /seasons/1.json
  def destroy
    @season = Season.find(params[:id])
    @season.destroy

    respond_to do |format|
      format.html { redirect_to seasons_url }
      format.json { head :no_content }
    end
  end
end
