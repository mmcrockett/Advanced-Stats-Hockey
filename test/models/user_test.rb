require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def assert_user_nil(user)
    user.attributes.each_pair do |attr, value|
      assert_nil(value)
    end
  end

  setup do
    @user = users(:one)
  end

  test "username isn't blank" do
    @user.username = ""
    @user.save
    assert(@user.errors.messages.include?(:username))
    assert_equal("can't be blank", @user.errors.messages[:username].first)
  end

  test "password isn't blank on create" do
    user1 = @user.dup
    user1.password = ""
    @user.password = ""
    @user.save
    user1.save
    assert(@user.errors.messages.empty?)
    assert(user1.errors.messages.include?(:password))
    assert_equal("can't be blank", user1.errors.messages[:password].first)
  end

  test "username is at least six characters" do
    @user.username = "a"
    @user.save
    assert(@user.errors.messages.include?(:username))
    assert_equal(1, @user.errors.messages[:username].length)
    assert_equal("is too short (minimum is 6 characters)", @user.errors.messages[:username].first)
  end

  test "username is less than 60 characters" do
    @user.username = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    @user.save
    assert(@user.errors.messages.include?(:username))
    assert_equal(1, @user.errors.messages[:username].length)
    assert_equal("is too long (maximum is 60 characters)", @user.errors.messages[:username].first)
  end

  test "username is unique" do
    user1 = @user.dup
    user1.save
    assert(user1.errors.messages.include?(:username))
    assert_equal(1, user1.errors.messages[:username].length)
    assert_equal("has already been taken", user1.errors.messages[:username].first)
  end

  test "password is at least six characters on create" do
    user1 = @user.dup
    user1.password = "a"
    @user.password = "a"
    user1.save
    @user.save
    assert(@user.errors.messages.empty?)
    assert(user1.errors.messages.include?(:password))
    assert_equal(1, user1.errors.messages[:password].length)
    assert_equal("is too short (minimum is 6 characters)", user1.errors.messages[:password].first)
  end

  test "password is less than 20 characters on create" do
    user1 = @user.dup
    user1.password = "aaaaaaaaaaaaaaaaaaaaa"
    @user.password = "aaaaaaaaaaaaaaaaaaaaa"
    user1.save
    @user.save
    assert(@user.errors.messages.empty?)
    assert(user1.errors.messages.include?(:password))
    assert_equal(1, user1.errors.messages[:password].length)
    assert_equal("is too long (maximum is 20 characters)", user1.errors.messages[:password].first)
  end

  test "setting password changes salt and results in new hashed_password" do
    salt  = @user.salt
    hpass = @user.hashed_password
    @user.password = "xxxxx"
    assert_not_equal(salt, @user.salt)
    assert_not_equal(hpass, @user.hashed_password)
    assert_equal(User.encrypted_password("xxxxx", @user.salt), @user.hashed_password)
  end

  test "salt exists" do
    @user.salt = ""
    @user.save
    assert(@user.errors.messages.include?(:salt))
    assert_equal(1, @user.errors.messages[:salt].length)
    assert_equal("can't be blank", @user.errors.messages[:salt].first)
  end

  test "hashed password exists" do
    @user.hashed_password = ""
    @user.save
    assert(@user.errors.messages.include?(:hashed_password))
    assert_equal(1, @user.errors.messages[:hashed_password].length)
    assert_equal("can't be blank", @user.errors.messages[:hashed_password].first)
  end

  test "user can register and authenticate" do 
    registered_user = User.register('testperson', 'testpassword')
    assert_equal('testperson', registered_user.username)

    user_authenticate = User.authenticate('testperson', 'testpassword')
    assert_equal(registered_user.id, user_authenticate.id)
  end

  test "bad authenticate returns empty User" do 
    [nil, "", "baduser"].each do |uname|
      user = User.authenticate(uname, 'password')
      assert_user_nil(user)
      #assert_equal(User.new, user)
    end
  end

  test "username is case insensitive, password is case sensitive" do 
    registered_user = User.register('testperson', 'testpassword')
    user = User.authenticate('TESTpERsON', 'testpassword')
    assert_equal(registered_user.id, user.id)
    user = User.authenticate('testperson', 'testPassword')
    assert_user_nil(user)
  end

  test "bad password or bad username returns empty User" do 
    registered_user = User.register('testperson', 'testpassword')

    user = User.authenticate('estperson', 'testpassword')
    assert_nil(user.id)

    user = User.authenticate('testperson', 'tstpassword')
    assert_user_nil(user)

    user = User.authenticate('testperson', registered_user.hashed_password)
    assert_user_nil(user)
  end
end
