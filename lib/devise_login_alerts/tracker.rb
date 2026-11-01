module DeviseLoginAlerts
  class Tracker
    USER_AGENT_LIMIT = 512

    def initialize(user, request, scope:)
      @user = user
      @request = request
      @scope = scope.to_s
    end

    # The cookie is written last so a failure anywhere before it leaves the browser unknown, and the next sign-in alerts.
    def record_success(alert: true)
      cookie = DeviceCookie.new(@request)
      had_devices = @user.login_devices.exists?

      attempt = LoginAttempt.transaction do
        device = touch_device(cookie.token!)
        create_attempt(successful: true, device: device, new_device: device.previously_new_record?)
      end

      deliver_alert(attempt) if attempt.new_device? && alert && alert?(attempt, had_devices)
      cookie.write!
      emit(:sign_in, attempt, first_device: !had_devices)
      attempt
    end

    def record_failure(reason)
      token = DeviceCookie.new(@request).token
      device = token && @user.login_devices.find_by(token_digest: DeviceCookie.digest(@user, token))

      attempt = create_attempt(successful: false, failure_reason: reason.to_s, device: device, new_device: device.nil?)
      emit(:failed_sign_in, attempt)
      attempt
    end

    private

    def touch_device(token)
      digest = DeviceCookie.digest(@user, token)
      device = @user.login_devices.find_or_initialize_by(token_digest: digest)
      Device.transaction(requires_new: true) { device.update!(user_agent: user_agent, last_seen_at: Time.current) }
      device
    rescue ActiveRecord::RecordNotUnique
      @user.login_devices.find_by!(token_digest: digest)
    end

    def create_attempt(**attributes)
      ip = IpResolver.call(@request)
      @user.login_attempts.create!(
        scope: @scope, ip: ip, user_agent: user_agent, **LocationResolver.call(@request, ip), **attributes
      )
    end

    def emit(name, attempt, first_device: false)
      event = Event.new(name: name, login_attempt: attempt, first_device: first_device && attempt.new_device?)
      safely { ActiveSupport::Notifications.instrument("#{name}.devise_login_alerts", event: event, login_attempt: attempt) }
      safely { config.on_event&.call(event) }
    end

    def safely
      yield
    rescue StandardError => e
      Rails.error.report(e, handled: true, source: 'devise_login_alerts')
    end

    def alert?(attempt, had_devices)
      return false unless had_devices || config.alert_on_first_device
      return false if config.skip_alert_if&.call(@user, attempt)

      @user.send_login_alert?(attempt)
    end

    def deliver_alert(attempt)
      message = config.mailer.constantize.with(login_attempt: attempt).new_device_login
      config.deliver_later ? message.deliver_later : message.deliver_now
      attempt.update!(alerted: true)
    end

    def user_agent
      @request.user_agent.to_s.truncate(USER_AGENT_LIMIT).presence
    end

    def config
      DeviseLoginAlerts.config
    end
  end
end
