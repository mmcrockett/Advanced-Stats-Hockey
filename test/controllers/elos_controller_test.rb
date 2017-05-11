require 'test_helper'

class ElosControllerTest < ActionController::TestCase
  setup do
    @elo = elos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:elos)

    logged_in
    get :index
    assert_response :success
    assert_not_nil assigns(:elos)
  end

  test "should create elo only when logged in" do
    assert_no_difference('Elo.count') do
      post :create, elo: { sample_date: @elo.sample_date, team_id: @elo.team_id, value: @elo.value, game_id:@elo.game_id }
    end
    assert_response :unauthorized

    logged_in
    assert_difference('Elo.count') do
      post :create, elo: { sample_date: @elo.sample_date, team_id: @elo.team_id, value: @elo.value, game_id:@elo.game_id }
    end
    assert_redirected_to elo_path(assigns(:elo))
  end

  test "should get edit only when logged in" do
    get :edit, id: @elo
    assert_response :unauthorized

    logged_in
    get :edit, id: @elo
    assert_response :success
  end

  test "should update elo only when logged in" do
    expected_value = @elo.value
    new_value = 1232
    patch :update, id: @elo, elo: { sample_date: @elo.sample_date, team_id: @elo.team_id, value: new_value }
    @elo.reload
    assert_equal(expected_value, @elo.value)
    assert_response :unauthorized

    logged_in
    patch :update, id: @elo, elo: { sample_date: @elo.sample_date, team_id: @elo.team_id, value: new_value }
    @elo.reload
    assert_equal(new_value, @elo.value)
    assert_redirected_to elo_path(assigns(:elo))
  end
end
