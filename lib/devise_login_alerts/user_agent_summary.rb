module DeviseLoginAlerts
  module UserAgentSummary
    BROWSERS = [
      ['Edge', %r{Edg(e|A|iOS)?/}],
      ['Opera', %r{OPR/|Opera}],
      ['Samsung Internet', /SamsungBrowser/],
      ['Firefox', %r{Firefox/|FxiOS}],
      ['Chrome', %r{Chrome/|CriOS}],
      ['Safari', %r{Safari/}]
    ].freeze

    PLATFORMS = [
      ['iOS', /iPhone|iPad|iPod/],
      ['Android', /Android/],
      ['ChromeOS', /CrOS/],
      ['Windows', /Windows/],
      ['macOS', /Macintosh|Mac OS X/],
      ['Linux', /Linux/]
    ].freeze

    module_function

    def call(user_agent)
      return if user_agent.blank?

      browser = match(BROWSERS, user_agent)
      platform = match(PLATFORMS, user_agent)
      return user_agent.truncate(80) unless browser || platform

      [browser, platform].compact.join(' on ')
    end

    def match(patterns, user_agent)
      patterns.find { |_name, pattern| user_agent.match?(pattern) }&.first
    end
  end
end
