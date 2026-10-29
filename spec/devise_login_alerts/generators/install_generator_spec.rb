require 'generators/devise_login_alerts/install_generator'

RSpec.describe DeviseLoginAlerts::Generators::InstallGenerator do
  let(:destination) { Dir.mktmpdir }

  after { FileUtils.remove_entry(destination) }

  it 'creates the initializer and a timestamped migration' do
    described_class.start(['--quiet'], destination_root: destination)

    expect(File).to exist(File.join(destination, 'config/initializers/devise_login_alerts.rb'))
    migration = Dir[File.join(destination, 'db/migrate/*_create_devise_login_alerts.rb')].sole
    expect(File.basename(migration)).to match(/\A\d{14}_/)
    expect(File.read(migration)).to include("ActiveRecord::Migration[#{ActiveRecord::VERSION::STRING.to_f}]")
  end
end
