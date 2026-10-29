RSpec.describe DeviseLoginAlerts::Mailer do
  subject(:mail) { described_class.with(login_attempt: attempt).new_device_login }

  let(:user) { User.create!(name: 'Ada', email: 'ada@example.com', password: 'correct-horse') }
  let(:attempt) do
    user.login_attempts.create!(
      scope: 'user', successful: true, new_device: true, ip: '203.0.113.9', country_code: 'GB', city: 'Manchester',
      user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Gecko/20100101 Firefox/131.0',
      created_at: Time.utc(2026, 10, 29, 14, 3)
    )
  end

  it 'is addressed to the account owner from the Devise sender' do
    expect(mail.to).to eq(['ada@example.com'])
    expect(mail.from).to eq(['security@example.com'])
    expect(mail.subject).to eq('New sign-in to your Dummy account')
  end

  it 'describes when, where and on what the sign-in happened' do
    bodies = [mail.html_part, mail.text_part].map { |part| part.body.decoded }

    expect(bodies).to all(include('Hi Ada,', 'ada@example.com', 'Manchester, GB', '203.0.113.9', 'Firefox on Windows',
                                  'October 29, 2026 14:03', 'http://example.com/users/password/new'))
  end

  it 'names the country with the configured lookup' do
    DeviseLoginAlerts.config.country_name = ->(code) { { 'GB' => 'United Kingdom' }[code] }

    expect(mail.text_part.body.decoded).to include('Manchester, United Kingdom')
  end

  it 'falls back gracefully when the location and device are unknown' do
    attempt.update!(country_code: nil, city: nil, user_agent: nil)

    expect(mail.text_part.body.decoded).to include('Where: Unknown', 'Device: Unknown')
  end

  it 'uses the configured sender, app name and security link' do
    DeviseLoginAlerts.configure do |config|
      config.mailer_sender = -> { 'alerts@example.com' }
      config.app_name = 'Studio'
      config.security_url = ->(alerted_user, _attempt) { "https://example.com/account/#{alerted_user.id}" }
    end

    expect(mail.from).to eq(['alerts@example.com'])
    expect(mail.subject).to eq('New sign-in to your Studio account')
    expect(mail.text_part.body.decoded).to include("https://example.com/account/#{user.id}")
  end
end
