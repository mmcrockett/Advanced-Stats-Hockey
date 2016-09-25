require 'test_helper'

class SeasonsControllerTest < ActionController::TestCase
  setup do
    @season = seasons(:complete)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:seasons)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create season" do
    assert_difference('Season.count') do
      post :create, season: { complete: @season.complete, name: @season.name, pointhog_url: @season.pointhog_url}
    end

    assert_redirected_to seasons_url
  end

  test "should get edit" do
    get :edit, id: @season
    assert_response :success
  end

  test "should update season" do
    patch :update, id: @season, season: { complete: @season.complete, name: @season.name, pointhog_url: @season.pointhog_url }
    assert_redirected_to seasons_url
  end
end
