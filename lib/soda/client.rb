#!/usr/bin/env ruby
# Just a simple wrapper for SODA 2.0

require 'net/https'
require 'uri'
require 'json'
require 'cgi'
require 'hashie'
require 'curb'

module SODA
  class Client
    def initialize(config = {})
      @config = config.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end

    def get(resource, params = {})
      connection(:get, resource, nil, params)
    end

    def post(resource, body = "", params = {})
      connection(:post, resource, body, params)
    end

    def put(resource, body = "", params = {})
      connection(:put, resource, body, params)
    end

    def delete(resource, body = "", params = {})
      connection(:delete, resource, body, params)
    end

    def upload_file(path, filename, params = {}, field = 'file', remote_filename = filename)
      # c = Curl::Easy.new("https://#{@config[:domain]}#{path}?#{query_string(params)}")
      # c.multipart_form_post = true
      # c.http_auth_types = :basic
      # c.username = @config[:username]
      # c.password = @config[:password]
      # c.headers['X-App-Token'] = @config[:app_token]
      # c.http_post(Curl::PostField.file(field, filename, remote_filename))

      # puts c.body_str.inspect
      # return Hashie::Mash.new(JSON.parse(c.body_str))

      query = query_string(params)

      # If we didn't get a full path, assume "/resource/"
      if !resource.start_with?("/")
        resource = "/resource/" + resource
      end

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.add_field("X-App-Token", @config[:app_token])
      request.content_type = "application/json"
      request.body = body.to_json

      # Authenticate if we're supposed to
      if @config[:username]
        request.basic_auth @config[:username], @config[:password]
      end

      # BAM!
      return handle_response(http.request(request))
    end

    def post_form(path, fields = {}, params = {})
      query = query_string(params)
      resource = resoure_path(path)

      # Create our request
      uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      if @config[:ignore_ssl]
        http.auth.ssl.verify_mode = openssl::ssl::verify_none
      end

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
        if response.code != "200"
          raise "Error in request: #{response.body}"
        else
          if response["Content-Type"].include?("application/json")
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

      def connection(method, resource, body ="", params = {})
        method ||= :Get
        method = method.to_sym.capitalize

        query = query_string(params)

        if method === :Delete
            if !resource.start_with?("/")
              resource = "/resource/" + resource 
            end
            uri = URI.parse("https://#{@config[:domain]}#{resource}.json?#{query}")
        else
          path = resource_path(resource)
          uri = URI.parse("https://#{@config[:domain]}#{path}?#{query}")
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = eval("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
        
        if method === :Post || :Put || :Delete
          request = eval("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
          request.content_type = "application/json"
          request.body = body.to_json      
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

  end
end
