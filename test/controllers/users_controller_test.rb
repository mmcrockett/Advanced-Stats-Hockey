require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should create user" do
    assert_nil(session[:user_id])

    assert_difference('User.count') do
      post :create, {:user => { password: 'somepassword', username: 'someuser'}, :commit => "Register"}
    end

    assert_redirected_to('/')
  end

  test "failure on create should report error." do
    assert_nil(session[:user_id])

    assert_no_difference('User.count') do
      post :create, {:user => { password: 'abc', username: 'someuser'}, :commit => "Register"}
    end

    user = assigns['user']

    assert_nil(user.id)
    assert_equal(1, user.errors.full_messages.size)
    assert_equal("is too short (minimum is 6 characters)", user.errors.messages[:password].first)
  end

  test "should login user" do
    post :create, {:user => {:username => 'bbobberson', :password => 'somepassword'}}

    assert_equal(1, session[:user_id])
    assert_redirected_to('/')
  end

  test "should fail login user" do
    post :create, {:user => { password: 'badpassword', username: 'bbobberson'}}

    user = assigns['user']

    assert_nil(user.id)
    assert_equal(1, user.errors.full_messages.size)
    assert_equal(User::AUTHENTICATION_ERROR, user.errors.full_messages.first)
  end

  test "should logout user" do
    get :logout

    assert_nil(session[:user_id])
    assert_nil(assigns['user'])
    assert_redirected_to('/')
  end

  test "should logout when user is invalid" do
    @request.session[:user_id] = -1

    get :logout

    assert_equal(0, session.keys.size)
    assert_nil(assigns['user'])
    assert_redirected_to('/')
  end
end
