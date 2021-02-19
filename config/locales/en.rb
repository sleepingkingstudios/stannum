# frozen_string_literal: true

{
  en: {
    stannum: {
      greeting: lambda do |_key, options|
        if options[:name] == 'starfighter'
          'Greetings, %{name}! You have been recruited by the Star League' \
          ' to defend the frontier against Xur and the Ko-Dan armada!'
        else
          'Greetings, %{name}!'
        end
      end,
      hello:    'hello %{name}',
      invalid:  'is invalid',
      valid:    'is valid'
    }
  }
}
