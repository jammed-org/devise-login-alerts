require 'devise'
require 'devise_login_alerts/version'
require 'devise_login_alerts/configuration'
require 'devise_login_alerts/ip_resolver'
require 'devise_login_alerts/location_resolver'
require 'devise_login_alerts/device_cookie'
require 'devise_login_alerts/user_agent_summary'
require 'devise_login_alerts/tracker'
require 'devise_login_alerts/engine'

module DeviseLoginAlerts
  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end

  def self.reset_config!
    @config = Configuration.new
  end

  def self.table_name_prefix
    'devise_login_alerts_'
  end

  def self.record_failure(user, request, reason:, scope: Devise::Mapping.find_scope!(user))
    Tracker.new(user, request, scope: scope).record_failure(reason)
  end

  def self.purge!(now: Time.current)
    LoginAttempt.where(created_at: ...(now - config.attempt_retention)).in_batches.delete_all
    stale_devices(now - config.device_retention).in_batches.delete_all
  end

  # Each user's newest device is kept, so an account with no devices left can't take a silent first sign-in.
  def self.stale_devices(cutoff)
    table = Device.quoted_table_name

    Device.where(last_seen_at: ...cutoff).where(<<~SQL.squish)
      EXISTS (SELECT 1 FROM #{table} newer WHERE newer.user_type = #{table}.user_type
      AND newer.user_id = #{table}.user_id AND newer.last_seen_at > #{table}.last_seen_at)
    SQL
  end
end

Devise.add_module :login_alertable, model: 'devise_login_alerts/model'
