require 'devise_login_alerts/hooks'

module Devise
  module Models
    module LoginAlertable
      extend ActiveSupport::Concern

      included do
        has_many :login_attempts, as: :user, class_name: 'DeviseLoginAlerts::LoginAttempt', dependent: :delete_all
        has_many :login_devices, as: :user, class_name: 'DeviseLoginAlerts::Device', dependent: :delete_all
      end

      def send_login_alert?(_login_attempt)
        true
      end
    end
  end
end
