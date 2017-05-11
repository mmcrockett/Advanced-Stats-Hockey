require 'test_helper'

class TeamsControllerTest < ActionController::TestCase
  setup do
    @team = teams(:team_a)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:teams)

    logged_in
    get :index
    assert_response :success
    assert_not_nil assigns(:teams)
  end

  test "should create team only when logged in" do
    assert_no_difference('Team.count') do
      post :create, team: { franchise: @team.franchise, name: @team.name, season_id: @team.season_id }
    end
    assert_response :unauthorized

    logged_in
    set_back("blah")
    assert_difference('Team.count') do
      post :create, team: { franchise: @team.franchise, name: @team.name, season_id: @team.season_id }
    end
    assert_redirected_to "blah"
  end

  test "should get edit only when logged in" do
    get :edit, id: @team
    assert_response :unauthorized

    logged_in
    get :edit, id: @team
    assert_response :success
  end

  test "should update team only when logged in" do
    expected_name = @team.name
    new_name = 'Hello'
    patch :update, id: @team, team: { franchise: @team.franchise, name: new_name, season_id: @team.season_id }
    @team.reload
    assert_equal(expected_name, @team.name)
    assert_response :unauthorized

    logged_in
    set_back(edit_team_path(@team))
    patch :update, id: @team, team: { franchise: @team.franchise, name: new_name, season_id: @team.season_id }
    @team.reload
    assert_equal(new_name, @team.name)
    assert_redirected_to edit_team_path(@team)
  end
end
