class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable, :login_alertable

  def active_for_authentication?
    super && !disabled?
  end
end
