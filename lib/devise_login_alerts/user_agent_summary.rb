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

      [match(BROWSERS, user_agent), match(PLATFORMS, user_agent)].compact.join(' on ').presence
    end

    def match(patterns, user_agent)
      patterns.find { |_name, pattern| user_agent.match?(pattern) }&.first
    end
  end
end
