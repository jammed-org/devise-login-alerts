require 'ipaddr'

module DeviseLoginAlerts
  module IpResolver
    CLOUDFLARE_HEADER = 'CF-Connecting-IP'.freeze

    # https://www.cloudflare.com/ips/
    CLOUDFLARE_RANGES = %w[
      173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18
      190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13
      104.24.0.0/14 172.64.0.0/13 131.0.72.0/22
      2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32 2405:8100::/32 2a06:98c0::/29 2c0f:f248::/32
    ].map { |range| IPAddr.new(range) }.freeze

    module_function

    def call(request)
      ip = resolve(request, DeviseLoginAlerts.config.ip_resolver)
      ip_address?(ip) ? ip : request.remote_ip
    end

    def resolve(request, resolver)
      case resolver
      when :remote_ip then request.remote_ip
      when :ip then request.ip
      when :cloudflare then cloudflare(request)
      when String then header(request, resolver)
      else resolver.call(request)
      end
    end

    def cloudflare(request)
      return request.remote_ip if DeviseLoginAlerts.config.verify_cloudflare_peer && !cloudflare_ip?(request.remote_ip)

      header(request, CLOUDFLARE_HEADER) || request.remote_ip
    end

    def header(request, name)
      value = request.get_header("HTTP_#{name.upcase.tr('-', '_')}")
      value.to_s.split(',').first&.strip.presence
    end

    def ip_address?(value)
      return false unless value.is_a?(String) && value.match?(/\A[0-9a-fA-F.:]{2,45}\z/)

      IPAddr.new(value)
      true
    rescue IPAddr::Error
      false
    end

    def cloudflare_ip?(ip)
      address = IPAddr.new(ip.to_s)
      CLOUDFLARE_RANGES.any? { |range| range.include?(address) }
    rescue IPAddr::Error
      false
    end
  end
end
