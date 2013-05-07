#!/usr/bin/env ruby
# Just a simple wrapper for SODA 2.0

require 'net/https'
require 'uri'
require 'json'
require 'cgi'
require 'hashie'

module SODA
  class Client
    def initialize(config = {})
      @config = config.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    def get(resource, params = {})
      query = query_string(params)

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

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}#{extension}?#{query}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      if @config[:ignore_ssl]
        http.auth.ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Get.new(uri.request_uri)
      request.add_field("X-App-Token", @config[:app_token])

      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      end

      # BAM!
      response = http.request(request)

      # Check our response code
      if response.code != "200"
        raise "Error querying \"#{uri.to_s}\": #{response.body}"
      else
        if extension == ".json"
          # Return a bunch of mashes if we're JSON
          response = JSON::parse(response.body)
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

    def post(resource, body = "", params = {})
      query = query_string(params)

      # If we didn't get a full path, assume "/resource/"
      if !resource.start_with?("/")
        resource = "/resource/" + resource
      end

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      if @config[:ignore_ssl]
        http.auth.ssl.verify_mode = openssl::ssl::verify_none
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.add_field("X-App-Token", @config[:app_token])
      request.content_type = "application/json"
      request.body = body.to_json

      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      end

      # BAM!
      response = http.request(request)

      # Check our response code
      if response.code != "200"
        raise "Error querying \"#{uri.to_s}\": #{response.body}"
      else
        # Return a bunch of mashes
        response = JSON::parse(response.body)
        if response.is_a? Array
          return response.collect { |r| Hashie::Mash.new(r) }
        else
          return Hashie::Mash.new(response)
        end
      end
    end

    def put(resource, body = "", params = {})
      query = query_string(params)
      if @config[:ignore_ssl]
        http.auth.ssl.verify_mode = openssl::ssl::verify_none
      end

      # If we didn't get a full path, assume "/resource/"
      if !resource.start_with?("/")
        resource = "/resource/" + resource
      end

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      if @config[:ignore_ssl]
        http.auth.ssl.verify_mode = openssl::ssl::verify_none
      end

      request = Net::HTTP::Put.new(uri.request_uri)
      request.add_field("X-App-Token", @config[:app_token])
      request.content_type = "application/json"
      request.body = body.to_json

      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      end

      # BAM!
      response = http.request(request)

      # Check our response code
      if response.code != "200"
        raise "Error querying \"#{uri.to_s}\": #{response.body}"
      else
        # Return a bunch of mashes
        response = JSON::parse(response.body)
        if response.is_a? Array
          return response.collect { |r| Hashie::Mash.new(r) }
        else
          return Hashie::Mash.new(response)
        end
      end
    end

    def delete(resource, body = "", params = {})
      query = query_string(params)

      # If we didn't get a full path, assume "/resource/"
      if !resource.start_with?("/")
        resource = "/resource/" + resource
      end

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Delete.new(uri.request_uri)
      request.add_field("X-App-Token", @config[:app_token])
      request.content_type = "application/json"
      request.body = body.to_json

      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      end

      # BAM!
      response = http.request(request)

      # Check our response code
      if response.code != "200"
        raise "Error querying \"#{uri.to_s}\": #{response.body}"
      else
        # Return a bunch of mashes
        return response
      end
    end

    private
      def query_string(params) 
        # Create query string of escaped key, value pairs
        return params.collect{ |key, val| "#{key}=#{CGI::escape(val.to_s)}" }.join("&")
      end
  end
end
