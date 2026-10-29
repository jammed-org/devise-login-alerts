module DeviseLoginAlerts
  module Hooks
    IGNORED_FAILURES = %i[unauthenticated timeout].freeze

    module_function

    def after_set_user(user, warden, options)
      return unless tracked?(user) && warden.authenticated?(options[:scope])
      return if user.respond_to?(:active_for_authentication?) && !user.active_for_authentication?
      return if remember_me_restore?(warden)

      request = ActionDispatch::Request.new(warden.env)
      Tracker.new(user, request, scope: options[:scope]).record_success(alert: !options[:skip_login_alert])
    rescue StandardError => e
      report(e)
    end

    def before_failure(env, options)
      reason = options[:message]
      mapping = Devise.mappings[options[:scope]]
      return if reason.blank? || IGNORED_FAILURES.include?(reason.to_sym) || mapping.nil?

      request = ActionDispatch::Request.new(env)
      user = find_user(mapping, request)
      Tracker.new(user, request, scope: mapping.name).record_failure(reason) if tracked?(user)
    rescue StandardError => e
      report(e)
    end

    def find_user(mapping, request)
      params = request.params[mapping.name.to_s]
      return unless params.is_a?(Hash)

      keys = mapping.to.authentication_keys
      conditions = (keys.is_a?(Hash) ? keys.keys : keys).index_with { |key| params[key.to_s] }
      return if conditions.values.any? { |value| !value.is_a?(String) || value.blank? }

      mapping.to.find_for_authentication(conditions)
    end

    def remember_me_restore?(warden)
      defined?(Devise::Strategies::Rememberable) && warden.winning_strategy.is_a?(Devise::Strategies::Rememberable)
    end

    def tracked?(user)
      user.respond_to?(:devise_modules) && user.devise_modules.include?(:login_alertable)
    end

    def report(error)
      Rails.error.report(error, handled: true, source: 'devise_login_alerts')
    end
  end
end

Warden::Manager.after_set_user except: :fetch do |user, warden, options|
  DeviseLoginAlerts::Hooks.after_set_user(user, warden, options)
end

Warden::Manager.before_failure do |env, options|
  DeviseLoginAlerts::Hooks.before_failure(env, options)
end
