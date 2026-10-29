RSpec.describe DeviseLoginAlerts::UserAgentSummary do
  {
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36' => 'Chrome on macOS',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36 Edg/130.0' => 'Edge on Windows',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1' => 'Safari on iOS',
    'Mozilla/5.0 (X11; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0' => 'Firefox on Linux',
    'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/26.0 Chrome/122.0 Mobile Safari/537.36' => 'Samsung Internet on Android'
  }.each do |user_agent, summary|
    it "summarises #{summary}" do
      expect(described_class.call(user_agent)).to eq(summary)
    end
  end

  it 'falls back to the raw user agent when nothing matches' do
    expect(described_class.call('curl/8.4.0')).to eq('curl/8.4.0')
  end

  it 'returns nil without a user agent' do
    expect(described_class.call(nil)).to be_nil
  end
end
