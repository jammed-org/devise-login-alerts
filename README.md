# devise_login_alerts

Sign-in history and "new device" alert emails for [Devise](https://github.com/heartcombo/devise).

- Records every successful and failed sign-in: IP, rough location, user agent, failure reason.
- Recognises returning browsers with a first-party cookie, and emails the account owner when a sign-in comes from a device it hasn't seen before.
- Works with any Devise model, and with two-factor gems that sign in only after the second step (such as `devise-otp`). A remember-me cookie restoring an expired session, or a sign-in that isn't kept in the session (HTTP Basic, API tokens), is not counted as a sign-in.
- The email, the IP source, the location lookup and when to alert are all configurable.

## Installation

```ruby
# Gemfile
gem 'devise_login_alerts'
```

```bash
bin/rails generate devise_login_alerts:install
bin/rails db:migrate
```

Add the module to your Devise model:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :login_alertable
end
```

That gives you:

```ruby
user.login_attempts                     # every recorded attempt
user.login_devices                      # browsers this user has signed in from
user.recent_login_attempts(20)          # newest first
user.last_successful_login_attempt
user.failed_login_attempts_since(1.day.ago)

attempt.successful?                     # and failure_reason, e.g. "invalid", "locked"
attempt.new_device?
attempt.location                        # "Manchester, GB", or nil
attempt.device_summary                  # "Firefox on Windows", or nil
attempt.created_at
```

Both associations are deleted with the user.

## How devices are recognised

On a successful sign-in the browser gets an `httponly`, `SameSite=Lax` cookie holding a random token. The database only stores an HMAC of that token, keyed to the user and your `secret_key_base`, so:

- a leaked database can't be turned back into working cookies;
- the same browser used by two accounts can't be linked across them.

There is no browser fingerprinting. A sign-in from a browser without a recognised cookie counts as a new device, so clearing cookies or using a private window triggers an alert. The email says so.

The first device a user ever signs in from is remembered silently, so existing users don't all get an email the day you install the gem. Set `alert_on_first_device = true` to change that.

## Choosing when to alert

Three layers, all optional:

```ruby
# Per model
class User < ApplicationRecord
  def send_login_alert?(login_attempt)
    !admin_impersonation? && super
  end
end

# Globally
DeviseLoginAlerts.config.skip_alert_if = ->(user, login_attempt) { user.email.end_with?('@example.test') }

# Per sign-in, e.g. right after accepting an invite
sign_in(user, skip_login_alert: true)
```

Skipped sign-ins are still recorded and their device is still remembered.

## Failed sign-ins

Failures raised by Devise's strategies (wrong password, locked, inactive account) are recorded against the account the submitted email belongs to. Unknown emails are ignored. Failures your own code detects, such as a wrong two-factor code, can be recorded explicitly:

```ruby
DeviseLoginAlerts.record_failure(user, request, reason: :invalid_otp)
```

Failed attempts never set the device cookie.

IP and location values are validated before they are stored, whichever resolver supplied them. An unrecognised user agent is never echoed into the email, since the client controls it.

## Configuration

```ruby
DeviseLoginAlerts.configure do |config|
  config.ip_resolver = :remote_ip          # :ip, :cloudflare, 'X-Real-IP', or ->(request) { ... }
  config.verify_cloudflare_peer = false    # with :cloudflare, only trust the header from Cloudflare addresses
  config.location_resolver = nil           # :cloudflare, or ->(request, ip) { { country_code: 'GB', city: 'Leeds' } }
  config.country_name = ->(code) { code }  # how a stored country code is shown in the email

  config.cookie_name = 'devise_login_alerts_device'
  config.cookie_lifetime = 1.year
  config.cookie_options = {}               # e.g. { domain: :all }

  config.alert_on_first_device = false
  config.skip_alert_if = nil

  config.mailer = 'DeviseLoginAlerts::Mailer'
  config.parent_mailer = 'ActionMailer::Base'
  config.mailer_sender = nil               # falls back to the parent mailer's default, then Devise.mailer_sender
  config.deliver_later = true
  config.app_name = -> { Rails.application.class.module_parent_name }
  config.security_url = nil                # defaults to the Devise "forgot password" URL for the scope

  config.attempt_retention = 90.days
  config.device_retention = 1.year
end
```

### IP addresses behind a proxy or CDN

`request.remote_ip` is right for most apps once Rails' trusted proxies are configured. Behind Cloudflare use `:cloudflare`, which reads `CF-Connecting-IP`. Anyone who can reach your origin directly can send that header, so either only accept traffic from Cloudflare or turn on `verify_cloudflare_peer`, which then also guards the `:cloudflare` location headers.

### Location

`:cloudflare` reads the `CF-IPCountry` and `CF-IPCity` headers. City needs Cloudflare's "Add visitor location headers" managed transform. Only the country code and city are stored, never coordinates. Emails show the code unless you set `country_name`, for example with the [`countries`](https://github.com/countries/countries) gem:

```ruby
config.country_name = ->(code) { ISO3166::Country[code]&.translation(I18n.locale.to_s) || code }
```

## The email

The alert says when, roughly where and on what browser and system the sign-in happened. The IP address is recorded for the history but kept out of the email.

Override `app/views/devise_login_alerts/mailer/new_device_login.{html,text}.erb` and the `devise_login_alerts.mailer.new_device_login.*` translations, or point `config.mailer` at your own mailer. A custom mailer must respond to `with(login_attempt:).new_device_login`. Set `parent_mailer` to reuse your app's layout and sender.

## Instrumentation

- `login_attempt.devise_login_alerts`, with `login_attempt:`, for every recorded attempt
- `new_device_alert.devise_login_alerts`, with `login_attempt:`, when an alert is sent

Tracking errors are reported through `Rails.error` and never block a sign-in.

## Retention and privacy

Sign-in records are personal data. Run the purge on a schedule:

```ruby
DeviseLoginAlerts.purge!
```

It deletes attempts older than `attempt_retention` and devices unused for `device_retention`, except each user's most recent device. Keeping that one means an account whose devices have all aged out doesn't treat its next sign-in, which may not be the owner's, as a silent first device. The device cookie is used only to secure sign-ins, which generally falls under the "strictly necessary" exemption from cookie consent (UK PECR, EU ePrivacy). Mention it in your privacy notice.

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT, see [LICENSE.txt](LICENSE.txt).
