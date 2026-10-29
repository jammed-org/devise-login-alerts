class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :login_alertable

  def active_for_authentication?
    super && !disabled?
  end
end
