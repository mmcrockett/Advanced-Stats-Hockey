ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def logged_in(user_id = 1)
    @request.session[:user_id] = user_id
  end

  def request_json
    @request.headers["Content-Type"] = 'application/json'
    @request.headers["Accept"]     = 'application/json'
  end

  def set_back(value)
    @request.env["HTTP_REFERER"] = value
  end
end
