RSpec.describe Devise::Models::LoginAlertable do
  let(:user) { User.create!(email: 'ada@example.com', password: 'correct-horse') }

  def attempt(successful:, at:)
    user.login_attempts.create!(scope: 'user', successful: successful, created_at: at)
  end

  describe '#recent_login_attempts' do
    it 'lists the newest attempts first, up to the limit' do
      oldest = attempt(successful: true, at: 3.days.ago)
      middle = attempt(successful: false, at: 2.days.ago)
      newest = attempt(successful: true, at: 1.day.ago)

      expect(user.recent_login_attempts).to eq([newest, middle, oldest])
      expect(user.recent_login_attempts(2)).to eq([newest, middle])
    end
  end

  describe '#last_successful_login_attempt' do
    it 'skips later failures' do
      success = attempt(successful: true, at: 2.days.ago)
      attempt(successful: false, at: 1.day.ago)

      expect(user.last_successful_login_attempt).to eq(success)
    end
  end

  describe '#failed_login_attempts_since' do
    it 'counts only failures inside the window' do
      attempt(successful: false, at: 3.days.ago)
      recent_failure = attempt(successful: false, at: 1.hour.ago)
      attempt(successful: true, at: 30.minutes.ago)

      expect(user.failed_login_attempts_since(1.day.ago)).to contain_exactly(recent_failure)
    end
  end

  it 'deletes the history with the user' do
    attempt(successful: true, at: 1.day.ago)
    user.login_devices.create!(token_digest: 'digest', last_seen_at: Time.current)

    expect { user.destroy }.to change(DeviseLoginAlerts::LoginAttempt, :count).by(-1)
                                                                              .and change(DeviseLoginAlerts::Device, :count).by(-1)
  end
end
