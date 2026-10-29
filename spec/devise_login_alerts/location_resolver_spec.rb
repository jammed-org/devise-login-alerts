RSpec.describe DeviseLoginAlerts::LocationResolver do
  def request_with(headers = {})
    env = Rack::MockRequest.env_for('/')
    headers.each { |name, value| env["HTTP_#{name.upcase.tr('-', '_')}"] = value }
    ActionDispatch::Request.new(env)
  end

  def resolve(resolver, request)
    DeviseLoginAlerts.config.location_resolver = resolver
    described_class.call(request, '203.0.113.9')
  end

  it 'returns nothing by default' do
    expect(described_class.call(request_with, '203.0.113.9')).to eq({})
  end

  it 'reads country and city from Cloudflare headers' do
    request = request_with('CF-IPCountry' => 'GB', 'CF-IPCity' => 'Manchester')

    expect(resolve(:cloudflare, request)).to eq(country_code: 'GB', city: 'Manchester')
  end

  it 'treats the Cloudflare unknown country as blank' do
    expect(resolve(:cloudflare, request_with('CF-IPCountry' => 'XX'))).to eq({})
  end

  it 'drops a country code that is not two letters or digits' do
    expect(resolve(:cloudflare, request_with('CF-IPCountry' => 'GBR'))).to eq({})
  end

  it 'strips control characters from the city and caps its length' do
    request = request_with('CF-IPCity' => "Man\nchester#{'x' * 200}")

    expect(resolve(:cloudflare, request)[:city]).to eq("Manchester#{'x' * 90}")
  end

  it 'sanitises what a callable returns too' do
    resolver = ->(_request, _ip) { { country_code: 'gb', city: "\t" } }

    expect(resolve(resolver, request_with)).to eq(country_code: 'GB')
  end

  it 'decodes a non-ASCII city' do
    request = request_with('CF-IPCity' => (+'Zürich').force_encoding(Encoding::BINARY))

    expect(resolve(:cloudflare, request)[:city]).to eq('Zürich')
  end

  context 'when verify_cloudflare_peer is on' do
    before { DeviseLoginAlerts.config.verify_cloudflare_peer = true }

    def request_from(remote_addr)
      request = request_with('CF-IPCountry' => 'GB', 'CF-IPCity' => 'Manchester')
      request.set_header('REMOTE_ADDR', remote_addr)
      request
    end

    it 'trusts location headers from a Cloudflare address' do
      expect(resolve(:cloudflare, request_from('173.245.48.10'))).to eq(country_code: 'GB', city: 'Manchester')
    end

    it 'ignores spoofed location headers from anywhere else' do
      expect(resolve(:cloudflare, request_from('198.51.100.4'))).to eq({})
    end
  end

  it 'keeps only the location keys a callable returns' do
    resolver = ->(_request, ip) { { country_code: 'FR', city: 'Paris', ip: ip, latitude: 48.8 } }

    expect(resolve(resolver, request_with)).to eq(country_code: 'FR', city: 'Paris')
  end
end
