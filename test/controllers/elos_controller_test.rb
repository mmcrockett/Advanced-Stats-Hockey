require 'test_helper'

class ElosControllerTest < ActionController::TestCase
  setup do
    @elo = elos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:elos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create elo" do
    assert_difference('Elo.count') do
      post :create, elo: { sample_date: @elo.sample_date, team_id: @elo.team_id, value: @elo.value }
    end

    assert_redirected_to elo_path(assigns(:elo))
  end

  test "should show elo" do
    get :show, id: @elo
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @elo
    assert_response :success
  end

  test "should update elo" do
    patch :update, id: @elo, elo: { sample_date: @elo.sample_date, team_id: @elo.team_id, value: @elo.value }
    assert_redirected_to elo_path(assigns(:elo))
  end

  test "should destroy elo" do
    assert_difference('Elo.count', -1) do
      delete :destroy, id: @elo
    end

    assert_redirected_to elos_path
  end
end
