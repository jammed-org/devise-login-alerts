require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'devise'
require 'devise_login_alerts'

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = 'dummy-secret-key-base-for-devise-login-alerts-specs'
    config.hosts.clear
    config.logger = Logger.new(nil)
    config.active_support.deprecation = :stderr
    config.action_controller.allow_forgery_protection = false
    config.action_dispatch.show_exceptions = :none
    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: 'example.com' }
    config.active_job.queue_adapter = :test
  end
end
