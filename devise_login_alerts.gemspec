require_relative 'lib/devise_login_alerts/version'

Gem::Specification.new do |spec|
  spec.name = 'devise_login_alerts'
  spec.version = DeviseLoginAlerts::VERSION
  spec.authors = ['Jammed']
  spec.summary = 'Sign-in history and new device alert emails for Devise.'
  spec.description = 'Records successful and failed Devise sign-ins, recognises returning browsers with a ' \
                     'first-party cookie, and emails the account owner when a sign-in comes from a new device.'
  spec.homepage = 'https://github.com/jammed-org/devise-login-alerts'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.files = Dir['{app,config,lib}/**/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'actionmailer', '>= 7.1', '< 9'
  spec.add_dependency 'activerecord', '>= 7.1', '< 9'
  spec.add_dependency 'devise', '>= 4.9', '< 6'
  spec.add_dependency 'railties', '>= 7.1', '< 9'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = "#{spec.homepage}#readme"
  spec.metadata['rubygems_mfa_required'] = 'true'
end
