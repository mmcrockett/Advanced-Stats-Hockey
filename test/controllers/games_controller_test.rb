require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  setup do
    @game = games(:game_0)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:games)

    logged_in
    get :index
    assert_response :success
    assert_not_nil assigns(:games)
  end

  test "should create game only when logged in" do
    assert_no_difference('Game.count') do
      post :create, game: { away_score: @game.away_score, away_team_id: @game.away_team_id, game_date: @game.game_date, home_score: @game.home_score, home_team_id: @game.home_team_id, overtime: @game.overtime }
    end
    assert_response :unauthorized

    logged_in
    set_back("blah")
    assert_difference('Game.count') do
      post :create, game: { away_score: @game.away_score, away_team_id: @game.away_team_id, game_date: @game.game_date, home_score: @game.home_score, home_team_id: @game.home_team_id, overtime: @game.overtime }
    end
    assert_redirected_to "blah"
  end

  test "should get edit only when logged in" do
    get :edit, id: @game
    assert_response :unauthorized

    logged_in
    get :edit, id: @game
    assert_response :success
  end

  test "should update game only when logged in" do
    expected_value = @game.away_score
    new_value = 1232
    patch :update, id: @game, game: { away_score: new_value, away_team_id: @game.away_team_id, game_date: @game.game_date, home_score: @game.home_score, home_team_id: @game.home_team_id, overtime: @game.overtime }
    @game.reload
    assert_equal(expected_value, @game.away_score)
    assert_response :unauthorized

    logged_in
    set_back(edit_game_path(@game))
    patch :update, id: @game, game: { away_score: new_value, away_team_id: @game.away_team_id, game_date: @game.game_date, home_score: @game.home_score, home_team_id: @game.home_team_id, overtime: @game.overtime }
    @game.reload
    assert_equal(new_value, @game.away_score)
    assert_redirected_to edit_game_path(@game)
  end
end
