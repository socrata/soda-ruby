#!/usr/bin/env ruby
#
# A Ruby client to the RESTful Socrata Open Data API
#
# For more details, check out http://socrata.github.io/soda-ruby
#

require 'net/https'
require 'uri'
require 'json'
require 'cgi'
require 'hashie'

module SODA
  class Client
    ##
    #
    # Creates a new SODA client.
    #
    # * +config+ - A hash of the options to initialize the client with
    #
    # == Config Options
    #
    # * +:domain+ - The domain you want to access
    # * +:username+ - Your Socrata username (optional, only necessary for modifying data)
    # * +:password+ - Your Socrata password (optional, only necessary for modifying data)
    # * +:app_token+ - Your Socrata application token (register at http://dev.socrata.com/register)
    # * +:ignore_ssl+ - Ignore ssl errors (defaults to false)
    #
    # Returns a SODA::Client instance.
    #
    # == Example
    #
    #   client = SODA::Client.new({ :domain => "data.agency.gov", :app_token => "CGxarwoQlgQSev4zyUh5aR5J3" })
    #
    def initialize(config = {})
      @config = config.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    ##
    #
    # Retrieve a resource via an HTTP GET request.
    #
    # * +resource+ - The resource identifier or path.
    # * +params+ - A hash of the URL parameters you want to pass
    #
    # Returns a Hashie::Mash that you can interact with as a Hash if you want.
    #
    # == Example
    #
    #   response = client.get("644b-gaut", { :firstname => "OPRAH", :lastname => "WINFREY", "$limit" => 5 })
    #
    def get(resource, params = {})
      connection(:get, resource, nil, params)
    end

    ##
    #
    # Update a resource via an HTTP POST request.
    #
    # Requires an authenticated client (both +:username+ and +:password+ passed into the +options+ hash)
    #
    # * +resource+ - The resource identifier or path.
    # * +body+ - The payload to POST. Will be converted to JSON (optional).
    # * +params+ - A hash of the URL parameters you want to pass (optional).
    #
    # Returns a Hashie::Mash that you can interact with as a Hash if you want.
    #
    # == Example
    #
    #   response = client.post("644b-gaut", [{ :firstname => "OPRAH", :lastname => "WINFREY" }])
    #
    def post(resource, body = nil, params = {})
      connection(:post, resource, body, params)
    end

    ##
    #
    # Replaces a resource via an HTTP PUT request.
    #
    # Requires an authenticated client (both +:username+ and +:password+ passed into the +options+ hash)
    #
    # * +resource+ - The resource identifier or path.
    # * +body+ - The payload to POST. Will be converted to JSON (optional).
    # * +params+ - A hash of the URL parameters you want to pass (optional).
    #
    # Returns a Hashie::Mash that you can interact with as a Hash if you want.
    #
    # == Example
    #
    #   response = client.put("644b-gaut", [{ :firstname => "OPRAH", :lastname => "WINFREY" }])
    #
    def put(resource, body = nil, params = {})
      connection(:put, resource, body, params)
    end

    ##
    #
    # Deletes a resource via an HTTP DELETE request.
    #
    # Requires an authenticated client (both +:username+ and +:password+ passed into the +options+ hash)
    #
    # * +resource+ - The resource identifier or path.
    # * +body+ - The payload to send with the DELETE. Will be converted to JSON (optional).
    # * +params+ - A hash of the URL parameters you want to pass (optional).
    #
    # Returns a Hashie::Mash that you can interact with as a Hash if you want.
    #
    # == Example
    #
    #   response = client.delete("644b-gaut")
    #
    def delete(resource, body = nil, params = {})
      connection(:delete, resource, body, params)
    end

    def post_form(path, fields = {}, params = {})
      query = query_string(params)
      resource = resoure_path(path)

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
      http = build_http_client(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.request_uri)
      request.add_field("X-App-Token", @config[:app_token])
      request.set_form_data(fields)

      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      end

      # BAM!
      return handle_response(http.request(request))
    end

    private
      def query_string(params)
        # Create query string of escaped key, value pairs
        return params.collect{ |key, val| "#{key}=#{CGI::escape(val.to_s)}" }.join("&")
      end

      def resource_path(resource)
        # If we didn't get a full path, assume "/resource/"
        if !resource.start_with?("/")
          resource = "/resource/" + resource
        end

        # Check to see if we were given an output type
        extension = ".json"
        if matches = resource.match(/^(.+)(\.\w+)$/)
          resource = matches.captures[0]
          extension = matches.captures[1]
        end

        return resource + extension
      end

      def handle_response(response)
        # Check our response code
        if !["200", "202"].include? response.code
          raise "Error in request: #{response.body}"
        else
          if response.body.nil? || response.body.empty?
            return nil
          elsif response["Content-Type"].include?("application/json")
            # Return a bunch of mashes if we're JSON
            response = JSON::parse(response.body, :max_nesting => false)
            if response.is_a? Array
              return response.collect { |r| Hashie::Mash.new(r) }
            else
              return Hashie::Mash.new(response)
            end
          else
            # We don't partically care, just return the raw body
            return response.body
          end
        end
      end

      def connection(method = "Get", resource = nil, body = nil, params = {})
        method = method.to_sym.capitalize

        query = query_string(params)

        path = resource_path(resource)

        uri = URI.parse("https://#{@config[:domain]}#{path}?#{query}")

        http = build_http_client(uri.host, uri.port)
        request = eval("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
        request.add_field("X-App-Token", @config[:app_token])

        if method === :Post || :Put || :Delete
          request.content_type = "application/json"
          request.body = body.to_json(:max_nesting => false)
        end

        # Authenticate if we're supposed to

        if @config[:username]
          request.basic_auth @config[:username], @config[:password]
        end

        if method === :Delete
          response = http.request(request)
          # Check our response code
          if response.code != "200"
            raise "Error querying \"#{uri.to_s}\": #{response.body}"
          else
            # Return a bunch of mashes
            return response
          end
        else
          return handle_response(http.request(request))
        end
      end

      def build_http_client(host, port)
        http = Net::HTTP.new(host, port)
        http.use_ssl = true
        if @config[:ignore_ssl]
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        if @config[:timeout]
          http.read_timeout = @config[:timeout]
        end
        http
      end

  end
end
