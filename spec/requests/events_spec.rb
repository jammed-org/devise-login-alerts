RSpec.describe 'Sign-in events' do
  let!(:user) { User.create!(email: 'ada@example.com', password: 'correct-horse') }
  let(:events) { [] }

  before { DeviseLoginAlerts.config.on_event = ->(event) { events << event } }

  def sign_in_with(password: 'correct-horse')
    post '/users/sign_in', params: { user: { email: user.email, password: password } }
  end

  it "reports a user's first device as :first, without an alert" do
    sign_in_with

    expect(events.sole).to have_attributes(name: :sign_in, device: :first, successful?: true, alerted?: false, user: user)
  end

  it 'reports a sign-in from another browser as :new and alerted' do
    sign_in_with
    reset!
    sign_in_with

    expect(events.last).to have_attributes(name: :sign_in, device: :new, alerted?: true)
  end

  it 'reports a returning browser as :known' do
    sign_in_with
    delete '/users/sign_out'
    sign_in_with

    expect(events.last).to have_attributes(name: :sign_in, device: :known, alerted?: false)
  end

  it 'reports a failed attempt with its reason' do
    sign_in_with(password: 'wrong')

    expect(events.sole).to have_attributes(name: :failed_sign_in, successful?: false, failure_reason: 'invalid', device: :new)
  end

  it 'publishes the same events through ActiveSupport::Notifications' do
    payloads = []
    subscriber = ActiveSupport::Notifications.subscribe('sign_in.devise_login_alerts') { |*, payload| payloads << payload }

    sign_in_with

    expect(payloads.sole).to include(event: events.sole, login_attempt: user.login_attempts.sole)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it 'never lets a failing handler affect the sign-in or the device cookie', :reports_errors do
    DeviseLoginAlerts.config.on_event = ->(_event) { raise 'metrics down' }

    sign_in_with
    get '/secret'

    expect(response).to have_http_status(:ok)
    expect(cookies['devise_login_alerts_device']).to be_present
    expect(ReportedErrors.errors.map(&:message)).to include('metrics down')
  end
end
