require 'test_helper'

class ElosControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:elos)
  end

  test "should get google data" do
    get :graph
    assert_response :success
    assert_not_nil assigns(:data)

    request_json
    get :graph
    assert_response :success
    assert_not_nil assigns(:data)
  end
end
