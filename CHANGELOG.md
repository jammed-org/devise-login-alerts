# Changelog

## 0.1.0 (17 November 2026)

- Record successful and failed Devise sign-ins with IP, location and user agent.
- Recognise returning browsers with a hashed first-party cookie.
- Email the account owner on a sign-in from a new device, without the IP address.
- Configurable IP and location resolvers, including Cloudflare.
- Install generator and retention purge.
- `on_event` hook and ActiveSupport notifications for every sign-in and failed attempt, for metrics.
- `recent_login_attempts`, `last_successful_login_attempt` and `failed_login_attempts_since` on the model.
- Supports Ruby 3.2+, Rails 7.1+ and Devise 4.9+.
