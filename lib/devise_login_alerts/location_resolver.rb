module DeviseLoginAlerts
  module LocationResolver
    UNKNOWN_COUNTRY = 'XX'.freeze

    module_function

    def call(request, ip)
      resolver = DeviseLoginAlerts.config.location_resolver

      location = case resolver
                 when nil then {}
                 when :cloudflare then cloudflare(request)
                 else resolver.call(request, ip) || {}
                 end
      location.to_h.symbolize_keys.slice(:country_code, :city)
    end

    def cloudflare(request)
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
