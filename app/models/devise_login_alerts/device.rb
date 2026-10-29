module DeviseLoginAlerts
  class Device < ActiveRecord::Base
    belongs_to :user, polymorphic: true
    has_many :login_attempts, class_name: 'DeviseLoginAlerts::LoginAttempt', dependent: :nullify

    def summary
      UserAgentSummary.call(user_agent)
    end
  end
end
