RSpec.describe DeviseLoginAlerts::IpResolver do
  def request_with(remote_addr: '10.0.0.1', headers: {})
    env = Rack::MockRequest.env_for('/', 'REMOTE_ADDR' => remote_addr)
    headers.each { |name, value| env["HTTP_#{name.upcase.tr('-', '_')}"] = value }
    ActionDispatch::Request.new(env)
  end

  def resolve(resolver, request)
    DeviseLoginAlerts.config.ip_resolver = resolver
    described_class.call(request)
  end

  it 'defaults to request.remote_ip' do
    expect(described_class.call(request_with(remote_addr: '198.51.100.4'))).to eq('198.51.100.4')
  end

  it 'can use the raw Rack request.ip' do
    expect(resolve(:ip, request_with(remote_addr: '198.51.100.4'))).to eq('198.51.100.4')
  end

  it 'reads CF-Connecting-IP with :cloudflare' do
    request = request_with(headers: { 'CF-Connecting-IP' => '203.0.113.9' })

    expect(resolve(:cloudflare, request)).to eq('203.0.113.9')
  end

  it 'falls back to remote_ip when the Cloudflare header is missing' do
    expect(resolve(:cloudflare, request_with(remote_addr: '198.51.100.4'))).to eq('198.51.100.4')
  end

  context 'when verify_cloudflare_peer is on' do
    before { DeviseLoginAlerts.config.verify_cloudflare_peer = true }

    it 'trusts the header from a Cloudflare address' do
      request = request_with(remote_addr: '173.245.48.10', headers: { 'CF-Connecting-IP' => '203.0.113.9' })

      expect(resolve(:cloudflare, request)).to eq('203.0.113.9')
    end

    it 'ignores a spoofed header from anywhere else' do
      request = request_with(remote_addr: '198.51.100.4', headers: { 'CF-Connecting-IP' => '203.0.113.9' })

      expect(resolve(:cloudflare, request)).to eq('198.51.100.4')
    end
  end

  it 'reads the first address from a named header' do
    request = request_with(headers: { 'X-Real-IP' => '203.0.113.9, 10.0.0.2' })

    expect(resolve('X-Real-IP', request)).to eq('203.0.113.9')
  end

  it 'falls back to remote_ip when the header is not an IP address' do
    request = request_with(remote_addr: '198.51.100.4', headers: { 'CF-Connecting-IP' => 'Your bank, London' })

    expect(resolve(:cloudflare, request)).to eq('198.51.100.4')
  end

  it 'rejects a CIDR range in place of an address' do
    request = request_with(remote_addr: '198.51.100.4', headers: { 'X-Real-IP' => '203.0.113.0/24' })

    expect(resolve('X-Real-IP', request)).to eq('198.51.100.4')
  end

  it 'accepts an IPv6 address' do
    request = request_with(headers: { 'CF-Connecting-IP' => '2001:db8::1' })

    expect(resolve(:cloudflare, request)).to eq('2001:db8::1')
  end

  it 'accepts a callable' do
    expect(resolve(->(_request) { '192.0.2.1' }, request_with)).to eq('192.0.2.1')
  end
end
