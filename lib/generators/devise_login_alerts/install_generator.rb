require 'rails/generators'
require 'rails/generators/active_record'

module DeviseLoginAlerts
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def copy_initializer
        template 'initializer.rb', 'config/initializers/devise_login_alerts.rb'
      end

      def copy_migration
        migration_template 'migration.rb', 'db/migrate/create_devise_login_alerts.rb'
      end

      private

      def migration_version
        "[#{ActiveRecord::VERSION::STRING.to_f}]"
      end
    end
  end
end
