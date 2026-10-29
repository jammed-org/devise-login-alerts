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
    expect(resolve(:cloudflare, request_with('CF-IPCountry' => 'XX'))).to eq(country_code: nil, city: nil)
  end

  it 'decodes a non-ASCII city' do
    request = request_with('CF-IPCity' => (+'Zürich').force_encoding(Encoding::BINARY))

    expect(resolve(:cloudflare, request)[:city]).to eq('Zürich')
  end

  it 'keeps only the location keys a callable returns' do
    resolver = ->(_request, ip) { { country_code: 'FR', city: 'Paris', ip: ip, latitude: 48.8 } }

    expect(resolve(resolver, request_with)).to eq(country_code: 'FR', city: 'Paris')
  end
end
