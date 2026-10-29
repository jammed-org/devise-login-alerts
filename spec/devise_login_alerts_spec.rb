RSpec.describe DeviseLoginAlerts do
  let(:user) { User.create!(email: 'ada@example.com', password: 'correct-horse') }

  def attempt_at(time)
    user.login_attempts.create!(scope: 'user', successful: true, created_at: time)
  end

  def device_seen_at(time)
    user.login_devices.create!(token_digest: SecureRandom.hex, last_seen_at: time)
  end

  describe '.purge!' do
    it 'deletes attempts and devices older than their retention' do
      old_attempt = attempt_at(91.days.ago)
      fresh_attempt = attempt_at(89.days.ago)
      stale_device = device_seen_at(13.months.ago)
      fresh_device = device_seen_at(11.months.ago)

      described_class.purge!

      expect(DeviseLoginAlerts::LoginAttempt.all).to contain_exactly(fresh_attempt)
      expect(DeviseLoginAlerts::Device.all).to contain_exactly(fresh_device)
      expect { old_attempt.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { stale_device.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "keeps each user's newest device even when it is stale" do
      oldest = device_seen_at(3.years.ago)
      newest = device_seen_at(2.years.ago)

      described_class.purge!

      expect(user.login_devices).to contain_exactly(newest)
      expect { oldest.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'honours configured retention' do
      described_class.config.attempt_retention = 7.days
      attempt_at(8.days.ago)

      expect { described_class.purge! }.to change(DeviseLoginAlerts::LoginAttempt, :count).to(0)
    end
  end

  describe '.record_failure' do
    it 'records a failure raised outside the Devise strategies, such as a bad 2FA code' do
      request = ActionDispatch::Request.new(Rack::MockRequest.env_for('/', 'REMOTE_ADDR' => '198.51.100.4'))

      described_class.record_failure(user, request, reason: :invalid_otp)

      expect(user.login_attempts.sole).to have_attributes(successful: false, failure_reason: 'invalid_otp', scope: 'user', ip: '198.51.100.4')
    end
  end
end
