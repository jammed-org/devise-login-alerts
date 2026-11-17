# Agent instructions

Instructions for AI coding agents working on `devise_login_alerts`, a Rails engine gem that records Devise sign-ins and emails users when a sign-in comes from a new device. Read `README.md` first for what the gem does and how it is configured.

## Commands

```bash
bundle install
bundle exec rspec                                   # full suite, a few seconds
bundle exec rspec spec/requests/sign_in_tracking_spec.rb:34   # one example
bundle exec rubocop                                 # lint
bundle exec rubocop -a                              # safe autocorrect
```

Run both `rspec` and `rubocop` before saying a change is done. CI runs specs on Ruby 3.2, 3.3 and 3.4, and rubocop on 3.4.

## Layout

- `lib/devise_login_alerts.rb` – entry point, `configure`, `record_failure`, `purge!`.
- `lib/devise_login_alerts/hooks.rb` – Warden `after_set_user` / `before_failure` hooks. Every error here is rescued and reported through `Rails.error`; tracking must never break a sign-in.
- `lib/devise_login_alerts/tracker.rb` – records attempts, matches devices, decides whether to alert, emits events.
- `lib/devise_login_alerts/model.rb` – the `:login_alertable` Devise module.
- `lib/devise_login_alerts/device_cookie.rb` – the device cookie; only an HMAC of its token is stored.
- `lib/devise_login_alerts/{ip,location}_resolver.rb`, `user_agent_summary.rb` – request parsing and validation.
- `lib/devise_login_alerts/event.rb` – the value object passed to `on_event` and ActiveSupport notifications.
- `app/` – `LoginAttempt` and `Device` models, the mailer and its views.
- `lib/generators/` – install generator, initializer and migration templates.
- `spec/dummy/` – minimal Rails app the specs boot. The schema is built in `spec/spec_helper.rb` from the real migration template, so a schema change goes in `templates/migration.rb.tt`.

## Compatibility rules

The gem supports Ruby >= 3.2, Rails >= 7.1 and Devise >= 4.9 (< 6). Don't break them:

- No Ruby 3.3+ features or core-library methods. Rubocop targets 3.2 and will catch syntax, not core-library calls.
- No Rails 7.2+/8 APIs (for example `params.expect`). Check the Rails 7.1 docs when unsure.
- `Gemfile.lock` is deliberately not committed. Don't add it back; each CI Ruby resolves its own dependencies.
- Don't add runtime dependencies to the gemspec without asking. Optional integrations (Cloudflare, `countries`, metrics services) are configured with lambdas instead.

## Conventions

- Follow `.rubocop.yml`. Single or double quotes are both fine; use leading-dot method chains.
- Add specs for every behaviour change. Prefer request specs in `spec/requests` for anything in the sign-in flow; they go through real Devise and Warden.
- The spec helper fails any example that reports an error through `Rails.error` unless it is tagged `:reports_errors`. Don't tag an example just to silence a failure; find the error.
- User-facing behaviour changes need a line under the unreleased heading in `CHANGELOG.md` and, if configurable, a README update and a commented line in `lib/generators/devise_login_alerts/templates/initializer.rb.tt`.
- Email copy lives in `config/locales/en.yml`, not in the views.

## Security and privacy

This gem handles personal data and authentication. Be conservative:

- Never put the IP address in the email, and never echo an unrecognised user agent into it.
- Validate IP and location values before storing them, whatever resolver supplied them.
- Never store the raw device token; only the HMAC keyed to the user and `secret_key_base`.
- No browser fingerprinting.
- Nothing in the hooks may raise into the host app's sign-in.

If a change touches any of these, say so explicitly when you report back.

## Don'ts

- Don't bump `VERSION`, tag, build or push the gem unless asked.
- Don't commit or push unless asked.
- Don't edit `spec/dummy` to make a failing spec pass when the bug is in `lib/` or `app/`.
