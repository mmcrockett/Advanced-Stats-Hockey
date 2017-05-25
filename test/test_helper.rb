ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  STATUS_CODES = {
    "200" => "OK",
    "201" => "Created",
    "202" => "Accepted",
    "204" => "No Content",
    "403" => "Forbidden",
    "404" => "Not Found"
  }

  def setup
    pointhog_schedule_data = read_file("pointhog_scheduleDivisionSchedule.html")
    pointhog_schedule_data.gsub!(/Crown Kings/i, "Team A")
    pointhog_schedule_data.gsub!(/Highlanders/i, "Team B")
    pointhog_schedule_data.gsub!(/Junior Eh's/i, "Team C")
    pointhog_schedule_data.gsub!(/Simple Jacks/i, "Team D")
    pointhog_schedule_data.gsub!(/Mean Eyed Cats/i, "Team X")
    pointhog_schedule_data.gsub!(/Black Jack/i, "Team Y")
    FakeWeb.register_uri(:get, seasons(:complete).pointhog_url, fakeweb_response(:body => pointhog_schedule_data, :plain => true))
  end

  def read_file(filename)
    if (false == File.exist?(filename))
      filename2 = File.join('test', 'fixtures', filename)

      if (false == File.exist?(filename2))
        raise "Couldn't find file '#{filename}' or '#{filename2}'."
      else
        filename = filename2
      end
    end

    if (true == filename.end_with?(".json"))
      return JSON.parse(File.read(filename))
    else
      return File.read(filename)
    end
  end

  def fakeweb_response(params = {})
    response = {}

    if (nil != params[:body])
      if (true == params[:plain])
        response[:body] = params[:body]
      else
        response[:body] = params[:body].to_json
        response[:content_type] = 'application/json'
      end
    end

    if (nil != params[:status])
      status = "#{params[:status]}"

      if (false == STATUS_CODES.include?(status))
        raise "No code for #{status}."
      end

      response[:status] = [status, STATUS_CODES[status]]
    end

    return response
  end

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
