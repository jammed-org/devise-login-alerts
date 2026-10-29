# Changelog

## 0.1.0 (unreleased)

- Record successful and failed Devise sign-ins with IP, location and user agent.
- Recognise returning browsers with a hashed first-party cookie.
- Email the account owner on a sign-in from a new device.
- Configurable IP and location resolvers, including Cloudflare.
- Install generator, retention purge and ActiveSupport notifications.
- `recent_login_attempts`, `last_successful_login_attempt` and `failed_login_attempts_since` on the model.
