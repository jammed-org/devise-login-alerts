Devise.setup do |config|
  require 'devise/orm/active_record'

  config.mailer_sender = 'security@example.com'
  config.stretches = 1
  config.http_authenticatable = true
  config.navigational_formats = ['*/*', :html]
end
