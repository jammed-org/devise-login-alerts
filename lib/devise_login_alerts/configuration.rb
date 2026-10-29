module DeviseLoginAlerts
  class Configuration
    attr_accessor :ip_resolver, :verify_cloudflare_peer, :location_resolver, :country_name,
                  :cookie_name, :cookie_lifetime, :cookie_options,
                  :alert_on_first_device, :skip_alert_if,
                  :mailer, :parent_mailer, :mailer_sender, :deliver_later, :app_name, :security_url,
                  :attempt_retention, :device_retention

    def initialize
      @ip_resolver = :remote_ip
      @verify_cloudflare_peer = false
      @location_resolver = nil
      @country_name = ->(country_code) { country_code }
      @cookie_name = 'devise_login_alerts_device'
      @cookie_lifetime = 1.year
      @cookie_options = {}
      @alert_on_first_device = false
      @skip_alert_if = nil
      @mailer = 'DeviseLoginAlerts::Mailer'
      @parent_mailer = 'ActionMailer::Base'
      @mailer_sender = nil
      @deliver_later = true
      @app_name = -> { Rails.application.class.module_parent_name }
      @security_url = nil
      @attempt_retention = 90.days
      @device_retention = 1.year
    end

    def resolved_app_name
      app_name.respond_to?(:call) ? app_name.call : app_name
    end
  end
end
