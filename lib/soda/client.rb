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
require 'sys/uname'
require 'soda/version'
require 'soda/exceptions'
include Sys

module SODA
  class Client
    class << self
      def generate_user_agent
        if Gem.win_platform?
          return "soda-ruby/#{SODA::VERSION} (Windows; Ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"
        end
        "soda-ruby/#{SODA::VERSION} (#{Uname.uname.sysname}/#{Uname.uname.release}; Ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"
      end
    end

    def blank?(object)
      object.nil? || object.empty?
    end

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
    # * +:access_token+ - Your Socrata OAuth token (optional, https://dev.socrata.com/docs/authentication.html)
    # * +:ignore_ssl+ - Ignore SSL errors, which is very unsafe and only should be done in desperate circumstances (defaults to false)
    # * +:debug_stream+ - Set an output stream for debugging
    #
    # Returns a SODA::Client instance.
    #
    # == Example
    #
    #   client = SODA::Client.new({ :domain => "data.agency.gov", :app_token => "CGxarwoQlgQSev4zyUh5aR5J3" })
    #
    def initialize(config = {})
      @config = Hashie.symbolize_keys! config
      @user_agent = SODA::Client.generate_user_agent
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

    def post_form(resource, body = {}, params = {})
      # We'll combine any params we got from our base resource with
      # those passed in
      base = URI.parse(parse_resource(resource))
      query = [
        base.query,
        query_string(params)
      ].reject { |s| blank?(s) }.join '&'

      uri = URI.parse("https://#{base.host}#{base.path}?#{query}")

      request = Net::HTTP::Post.new(uri.request_uri)
      add_default_headers_to_request(request)
      request.set_form_data(body)

      # Authenticate if we're supposed to
      authenticate(request)

      # BAM!
      http = build_http_client(uri.host, uri.port)
      handle_response(http.request(request))
    end

    private

    def query_string(params)
      # Create query string of escaped key, value pairs
      params.map { |key, val| "#{key}=#{CGI.escape(val.to_s)}" }.join('&')
    end

    def parse_resource(resource)
      # If our resource starts with HTTPS, assume they've passed in a full URI
      return resource if resource.start_with?('https://')

      # If we didn't get a full path, assume "/resource/"
      resource = '/resource/' + resource unless resource.start_with?('/')

      # Check to see if we were given an output type
      extension = '.json'
      if matches = resource.match(/^(.+)(\.\w+)$/)
        resource = matches.captures[0]
        extension = matches.captures[1]
      end

      raise 'No base domain specified!' unless @config[:domain]
      "https://#{@config[:domain]}#{resource}#{extension}"
    end

    # Returns a response with a parsed body
    def handle_response(response)
      # Check our response code
      check_response_fail(response)
      return nil if blank?(response.body)

      # Return a bunch of mashes as the body if we're JSON
      response.body = JSON.parse(response.body, max_nesting: false)
      response.body = if response.body.is_a? Array
                        response.body.map { |r| Hashie::Mash.new(r) }
                      else
                        Hashie::Mash.new(response.body)
                      end

      response
    end

    def check_response_fail(response)
      return if %w(200 202).include? response.code

      # Adapted from RestClient's exception handling
      begin
        klass = SODA::Exceptions::EXCEPTIONS_MAP.fetch(response.code.to_i)

        raise klass.new(response, response.code)
      rescue KeyError
        raise RequestFailed.new(response, response.code)
      end
    end

    def connection(method = 'Get', resource = nil, body = nil, params = {})
      method = method.to_sym.capitalize

      # We'll combine any params we got from our base resource with
      # those passed in
      base = URI.parse(parse_resource(resource))
      query = [
        base.query,
        query_string(params)
      ].reject { |s| blank?(s) }.join '&'

      uri = URI.parse("https://#{base.host}#{base.path}?#{query}")

      request = eval("Net::HTTP::#{method}").new(uri.request_uri)
      add_default_headers_to_request(request)

      # Authenticate if we're supposed to
      authenticate(request)

      http = request_by_method(method, body, request, uri)
      send_request(method, http, request)
    end

    def send_request(method, http, request)
      return delete_method_response(http, request) if method === :Delete
      handle_response(http.request(request))
    end

    def delete_method_response(http, request)
      response = http.request(request)
      return response if response.code == '200'
      fail "Error querying \"#{uri}\": #{response.body}"
    end

    def net_http_class(method)
      Object.const_get("Net::HTTP::#{method}")
    end

    def request_by_method(method, body, request, uri)
      if [:Post, :Put, :Get].include?(method)
        request.content_type = 'application/json'
        request.body = body.to_json(:max_nesting => false)
      end

      build_http_client(uri.host, uri.port)
    end

    def build_http_client(host, port)
      http = Net::HTTP.new(host, port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @config[:ignore_ssl]
      http.open_timeout = @config[:timeout] if @config[:timeout]
      http.read_timeout = @config[:timeout] if @config[:timeout]
      http.set_debug_output(@config[:debug_stream]) if @config[:debug_stream]
      http
    end

    def authenticate(request)
      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      elsif @config[:access_token]
        request.add_field('Authorization', "OAuth #{@config[:access_token]}")
      end
    end

    def add_default_headers_to_request(request)
      request.delete('User-Agent')
      request.add_field('X-App-Token', @config[:app_token])
      request.add_field('User-Agent', @user_agent)
    end
  end
end
