class ApplicationController < ActionController::Base
  add_flash_types :success, :warning, :danger, :info
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private
  def elo_authorize
    if (1 != session[:user_id])
      respond_to do |format|
        format.html { render(:file => "#{Rails.root}/public/401", :layout => false, :status => 401) }
        format.json { render json: {}, status: :unauthorized }
      end
    end
  end
end
