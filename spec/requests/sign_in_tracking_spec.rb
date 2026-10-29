RSpec.describe 'Sign-in tracking' do
  let!(:user) { User.create!(name: 'Ada', email: 'ada@example.com', password: 'correct-horse') }
  let(:chrome_on_mac) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36' }

  def sign_in_with(password: 'correct-horse', email: user.email, headers: {})
    post '/users/sign_in', params: { user: { email: email, password: password } },
                           headers: { 'User-Agent' => chrome_on_mac }.merge(headers)
  end

  def new_browser
    reset!
  end

  context 'with the first device a user signs in from' do
    it 'remembers the device without sending an alert' do
      expect { sign_in_with }.not_to have_enqueued_mail(DeviseLoginAlerts::Mailer, :new_device_login)

      attempt = user.login_attempts.sole
      expect(attempt).to have_attributes(successful: true, new_device: true, alerted: false, scope: 'user',
                                         ip: '127.0.0.1', user_agent: chrome_on_mac)
      expect(user.login_devices.sole).to eq(attempt.device)
    end

    it 'sets an http-only device cookie that only holds a random token' do
      sign_in_with

      set_cookie = Array(response.headers['Set-Cookie']).join("\n")
      token = cookies['devise_login_alerts_device']
      expect(set_cookie).to match(/devise_login_alerts_device=[^;]+;.*httponly/i)
      expect(token).to match(DeviseLoginAlerts::DeviceCookie::TOKEN_FORMAT)
      expect(user.login_devices.sole.token_digest).not_to include(token)
    end

    it 'alerts when alert_on_first_device is enabled' do
      DeviseLoginAlerts.config.alert_on_first_device = true

      expect { sign_in_with }.to have_enqueued_mail(DeviseLoginAlerts::Mailer, :new_device_login)
    end
  end

  context 'when the user has signed in before' do
    before do
      sign_in_with
      new_browser
    end

    it 'alerts the user about a sign-in from a new browser' do
      expect { sign_in_with }.to have_enqueued_mail(DeviseLoginAlerts::Mailer, :new_device_login)
        .with(a_hash_including(params: { login_attempt: an_object_having_attributes(new_device: true, alerted: true) }))

      expect(user.login_attempts.recent.first).to have_attributes(new_device: true, alerted: true)
      expect(user.login_devices.count).to eq(2)
    end

    it 'does not alert when the user is told not to by the model' do
      allow_any_instance_of(User).to receive(:send_login_alert?).and_return(false) # rubocop:disable RSpec/AnyInstance

      expect { sign_in_with }.not_to have_enqueued_mail
      expect(user.login_attempts.recent.first).to have_attributes(new_device: true, alerted: false)
    end

    it 'does not alert when skip_alert_if says so' do
      DeviseLoginAlerts.config.skip_alert_if = ->(skipped_user, attempt) { skipped_user == user && attempt.new_device? }

      expect { sign_in_with }.not_to have_enqueued_mail
    end

    it 'does not alert for a sign-in made with skip_login_alert' do
      expect { post '/quick_sign_in', params: { id: user.id } }.not_to have_enqueued_mail

      expect(user.login_attempts.recent.first).to have_attributes(successful: true, new_device: true)
    end

    it 'sends the email straight away when deliver_later is off' do
      DeviseLoginAlerts.config.deliver_later = false

      expect { sign_in_with }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  context 'when the user returns on a known device' do
    before do
      sign_in_with
      delete '/users/sign_out'
    end

    it 'reuses the device and sends nothing' do
      expect { sign_in_with }.not_to have_enqueued_mail

      expect(user.login_devices.count).to eq(1)
      expect(user.login_attempts.recent.first).to have_attributes(new_device: false, device: user.login_devices.sole)
    end
  end

  it 'keys device digests to the user, so a shared browser is not linkable across accounts' do
    other = User.create!(email: 'grace@example.com', password: 'correct-horse')
    sign_in_with
    delete '/users/sign_out'
    sign_in_with(email: other.email)

    expect(user.login_devices.sole.token_digest).not_to eq(other.login_devices.sole.token_digest)
  end

  context 'with a failed sign-in' do
    it 'records a wrong password without remembering the device' do
      sign_in_with(password: 'wrong')

      expect(user.login_attempts.sole).to have_attributes(successful: false, failure_reason: 'invalid', device: nil, new_device: true)
      expect(user.login_devices).to be_empty
      expect(cookies['devise_login_alerts_device']).to be_nil
    end

    it 'links the failure to a known device' do
      sign_in_with
      delete '/users/sign_out'
      sign_in_with(password: 'wrong')

      expect(user.login_attempts.recent.first).to have_attributes(successful: false, new_device: false, device: user.login_devices.sole)
    end

    it 'records a correct password for an inactive account as a failure' do
      user.update!(disabled: true)

      sign_in_with

      expect(user.login_attempts.sole).to have_attributes(successful: false, failure_reason: 'inactive')
      expect(user.login_devices).to be_empty
    end

    it 'records nothing for an unknown email address' do
      expect { sign_in_with(email: 'nobody@example.com') }.not_to change(DeviseLoginAlerts::LoginAttempt, :count)
    end

    it 'records nothing when a signed-out visitor is bounced from a protected page' do
      expect { get '/secret' }.not_to change(DeviseLoginAlerts::LoginAttempt, :count)
    end
  end

  context 'when tracking fails part-way through a sign-in from a new browser', :reports_errors do
    before do
      sign_in_with
      new_browser
    end

    it 'does not remember the browser if the attempt cannot be saved, so the next sign-in still alerts' do
      allow(DeviseLoginAlerts::IpResolver).to receive(:call).and_raise(ActiveRecord::ValueTooLong).once

      expect { sign_in_with }.not_to(change { user.login_devices.count })
      expect(cookies['devise_login_alerts_device']).to be_blank

      allow(DeviseLoginAlerts::IpResolver).to receive(:call).and_call_original
      delete '/users/sign_out'
      expect { sign_in_with }.to have_enqueued_mail(DeviseLoginAlerts::Mailer, :new_device_login)
    end

    it 'does not remember the browser if the alert cannot be queued, so the next sign-in still alerts' do
      allow(DeviseLoginAlerts::Mailer).to receive(:with).and_raise(StandardError, 'queue unavailable').once

      sign_in_with
      expect(cookies['devise_login_alerts_device']).to be_blank

      allow(DeviseLoginAlerts::Mailer).to receive(:with).and_call_original
      delete '/users/sign_out'
      expect { sign_in_with }.to have_enqueued_mail(DeviseLoginAlerts::Mailer, :new_device_login)
    end
  end

  it 'never blocks the sign-in when tracking fails', :reports_errors do
    allow(DeviseLoginAlerts::Tracker).to receive(:new).and_raise(ActiveRecord::StatementInvalid, 'boom')

    sign_in_with
    get '/secret'

    expect(response).to have_http_status(:ok)
    expect(ReportedErrors.errors.map(&:message)).to include('boom')
  end

  context 'with Cloudflare in front' do
    before do
      DeviseLoginAlerts.config.ip_resolver = :cloudflare
      DeviseLoginAlerts.config.location_resolver = :cloudflare
    end

    it 'stores the visitor IP and rough location from the Cloudflare headers' do
      sign_in_with(headers: { 'CF-Connecting-IP' => '203.0.113.9', 'CF-IPCountry' => 'GB', 'CF-IPCity' => 'Manchester' })

      expect(user.login_attempts.sole).to have_attributes(ip: '203.0.113.9', country_code: 'GB', city: 'Manchester')
    end
  end
end
