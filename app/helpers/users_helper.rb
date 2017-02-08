module UsersHelper
  def logged_in?
    return ((nil != session[:user_id]) && (0 < session[:user_id]))
  end
end
