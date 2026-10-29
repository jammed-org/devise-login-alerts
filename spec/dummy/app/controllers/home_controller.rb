class HomeController < ApplicationController
  before_action :authenticate_user!, only: :secret

  def index
    head :ok
  end

  def secret
    head :ok
  end

  def quick_sign_in
    sign_in(User.find(params[:id]), skip_login_alert: true)
    head :ok
  end
end
