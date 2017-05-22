require 'test_helper'

class SeasonsControllerTest < ActionController::TestCase
  setup do
    @season = seasons(:complete)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:seasons)

    logged_in
    get :index
    assert_response :success
    assert_not_nil assigns(:seasons)

    request_json
    get :index
    assert_response :success
    assert_not_nil assigns(:seasons)
  end

  test "should get new only when logged in" do
    get :new
    assert_response :unauthorized
    logged_in
    get :new
    assert_response :success
  end

  test "should create season only when logged in" do
    assert_no_difference('Season.count') do
      post :create, season: { complete: @season.complete, name: @season.name, pointhog_url: @season.pointhog_url}
    end
    assert_response :unauthorized

    logged_in
    assert_difference('Season.count') do
      post :create, season: { complete: @season.complete, name: @season.name, pointhog_url: @season.pointhog_url}
    end

    assert_redirected_to seasons_url
  end

  test "should get edit only when logged in" do
    get :edit, id: @season
    assert_response :unauthorized
    logged_in
    get :edit, id: @season
    assert_response :success
  end

  test "should update season only when logged in" do
    expected_name = @season.name
    new_name = 'hello'
    patch :update, id: @season, season: { complete: @season.complete, name: new_name, pointhog_url: @season.pointhog_url }
    @season.reload
    assert_equal(expected_name, @season.name)
    assert_response :unauthorized

    logged_in
    patch :update, id: @season, season: { complete: @season.complete, name: new_name, pointhog_url: @season.pointhog_url }
    @season.reload
    assert_equal(new_name, @season.name)
    assert_redirected_to seasons_url
  end
end
