module DeviseLoginAlerts
  module LocationResolver
    UNKNOWN_COUNTRY = 'XX'.freeze
    COUNTRY_CODE = /\A[A-Z0-9]{2}\z/
    CITY_LIMIT = 100

    module_function

    def call(request, ip)
      resolver = DeviseLoginAlerts.config.location_resolver

      location = case resolver
                 when nil then {}
                 when :cloudflare then cloudflare(request)
                 else resolver.call(request, ip) || {}
                 end
      sanitize(location.to_h.symbolize_keys)
    end

    def sanitize(location)
      country_code = location[:country_code].to_s.upcase
      city = location[:city].to_s.gsub(/[[:cntrl:]]/, '').squish.truncate(CITY_LIMIT, omission: '')

      { country_code: (country_code if country_code.match?(COUNTRY_CODE)), city: city.presence }.compact
    end

    def cloudflare(request)
      return {} if DeviseLoginAlerts.config.verify_cloudflare_peer && !IpResolver.cloudflare_ip?(request.remote_ip)

      country = request.get_header('HTTP_CF_IPCOUNTRY').presence
      {
        country_code: (country unless country == UNKNOWN_COUNTRY),
        city: utf8(request.get_header('HTTP_CF_IPCITY')).presence
      }
    end

    def utf8(value)
      return if value.nil?

      value.dup.force_encoding(Encoding::UTF_8).scrub('')
    end
  end
end
