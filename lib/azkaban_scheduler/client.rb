require 'net/http'
require 'json'

module AzkabanScheduler
  class Client
    attr_reader :http

    def initialize(url, http_options = {}, client_headers={})
      uri = URI(url)
      @client_headers = client_headers

      @http = Net::HTTP.new(uri.host, uri.port, read_timeout=180)
      @http.use_ssl = uri.scheme == 'https'

      http_options.each do |key, value|
        @http.public_send(:"#{key}=", value)
      end
    end

    def get(path, params=nil, headers={})
      path += "?#{URI.encode_www_form(params)}" if params
      req = Net::HTTP::Get.new(path)
      send_request(req, @client_headers.merge(headers))
    end

    def post(path, params=nil, headers={})
      req = Net::HTTP::Post.new(path)
      req.set_form_data(params) if params
      send_request(req, @client_headers.merge(headers))
    end

    def multipart_post(path, params, headers={})
      req = Net::HTTP::Post::Multipart.new(path, params)
      send_request(req, @client_headers.merge(headers))
    end

    private

    def send_request(request, headers)
      request['Accept'] = 'application/json'
      headers = @client_headers.merge(headers)
      headers.each { |name, value| request[name] = value } if headers
      response = http.request(request)
      dump_response(response) if ENV['DUMP_AZKABAN_RESPONSES']
      response
    end

    def dump_response(response)
      puts "HTTP/#{response.http_version} #{response.code} #{response.message}"
      response.each_header do |name, value|
        puts "#{name}: #{value}"
      end
      puts
      puts "#{response.body}"
      puts "-" * 60
    end
  end
end
