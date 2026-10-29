require 'openssl'
require 'securerandom'

module DeviseLoginAlerts
  class DeviceCookie
    TOKEN_FORMAT = /\A[A-Za-z0-9_-]{43}\z/

    def self.digest(user, token)
      OpenSSL::HMAC.hexdigest('SHA256', secret, [user.class.base_class.name, user.id, token].join(':'))
    end

    def self.secret
      Rails.application.key_generator.generate_key('devise_login_alerts/device_token', 32)
    end

    def initialize(request)
      @request = request
    end

    def token
      value = @request.cookie_jar[config.cookie_name]
      value if value.is_a?(String) && value.match?(TOKEN_FORMAT)
    end

    def token!
      @token ||= token || SecureRandom.urlsafe_base64(32)
    end

    def write!
      @request.cookie_jar[config.cookie_name] = {
        value: token!,
        expires: config.cookie_lifetime.from_now,
        httponly: true,
        secure: @request.ssl?,
        same_site: :lax
      }.merge(config.cookie_options)
    end

    private

    def config
      DeviseLoginAlerts.config
    end
  end
end
