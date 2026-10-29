ENV['RAILS_ENV'] = 'test'
ENV['DATABASE_URL'] = 'sqlite3::memory:'

require_relative 'dummy/config/application'
Rails.application.initialize!
Rails.application.reload_routes!

require 'rspec/rails'
require 'erb'
require 'tmpdir'

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
    t.string :email, null: false
    t.string :encrypted_password, null: false
    t.string :reset_password_token
    t.datetime :reset_password_sent_at
    t.boolean :disabled, null: false, default: false
  end
end

migration_template = File.expand_path('../lib/generators/devise_login_alerts/templates/migration.rb.tt', __dir__)
migration_file = File.join(Dir.mktmpdir, 'create_devise_login_alerts.rb')
File.write(migration_file, ERB.new(File.read(migration_template)).result_with_hash(migration_version: "[#{ActiveRecord::VERSION::STRING.to_f}]"))
load migration_file
CreateDeviseLoginAlerts.migrate(:up)

class ReportedErrors
  def self.errors
    @errors ||= []
  end

  def report(error, **)
    self.class.errors << error
  end
end
Rails.error.subscribe(ReportedErrors.new)

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.include ActiveJob::TestHelper
  config.include ActionMailer::TestHelper

  config.before do
    ReportedErrors.errors.clear
    ActionMailer::Base.deliveries.clear
  end

  config.after do |example|
    DeviseLoginAlerts.reset_config!
    expect(ReportedErrors.errors).to be_empty unless example.metadata[:reports_errors]
  end
end
