require 'test_helper'

class ElosControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:elos)
  end

  test "should get lines" do
    get :money_lines
    assert_response :success
    assert_not_nil assigns(:money_lines)
  end

  test "should get google data" do
    get :graph
    assert_response :success

    request_json
    get :graph
    assert_response :success
    assert_not_nil assigns(:data)
    assert_not_nil assigns(:labels)

    response_json = JSON.parse(response.body)

    assert_equal(Hash, response_json.class)
    assert(true == response_json.include?('data'))
    assert(true == response_json.include?('labels'))
  end
end
