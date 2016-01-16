require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Socrata < OmniAuth::Strategies::OAuth2
      option :name, 'socrata'

      option :client_options,
             :site                   => 'https://opendata.socrata.com',
             :authorize_url          => 'http://opendata.socrata.com/oauth/authorize',
             :provider_ignores_state => true

      # Sets the UID from the user's info
      uid { raw_info['id'] }

      info do
        {
          :name  => raw_info['name'],
          :email => raw_info['email']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/users/current.json').parsed
      end
    end
  end
end
