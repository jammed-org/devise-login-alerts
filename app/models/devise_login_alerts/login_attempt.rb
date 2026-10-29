module DeviseLoginAlerts
  class LoginAttempt < ActiveRecord::Base
    belongs_to :user, polymorphic: true
    belongs_to :device, class_name: 'DeviseLoginAlerts::Device', optional: true

    scope :successful, -> { where(successful: true) }
    scope :failed, -> { where(successful: false) }
    scope :recent, -> { order(created_at: :desc) }

    def location
      [city, country_name].compact_blank.join(', ').presence
    end

    def country_name
      DeviseLoginAlerts.config.country_name.call(country_code) if country_code.present?
    end

    def device_summary
      UserAgentSummary.call(user_agent)
    end
  end
end
