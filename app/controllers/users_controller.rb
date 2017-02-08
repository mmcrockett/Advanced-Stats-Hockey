class UsersController < ApplicationController
  def index
    @user = User.new
  end

  def create
    filtered_params = user_params()

    if ("Register" == params[:commit])
      @user = User.register(filtered_params[:username], filtered_params[:password])
    else
      @user = User.authenticate(filtered_params[:username], filtered_params[:password])
    end

    respond_to do |format|
      if (true == @user.persisted?)
        session[:user_id] = @user.id
        format.html { redirect_to '/' }
      else
        format.html { render :index }
      end
    end
  end

  def logout
    reset_session
    redirect_to("/")
  end

  private
  def user_params
    return params.require(:user).permit(:username, :password)
  end
end
