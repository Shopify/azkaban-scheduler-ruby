require 'net/http'
require 'json'

module AzkabanScheduler
  class Client
    def initialize(url)
      uri = URI(url)
      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = uri.scheme == 'https'
    end

    def get(path, params=nil, headers=nil)
      path += "?#{URI.encode_www_form(params)}" if params
      req = Net::HTTP::Get.new(path)
      send_request(req, headers)
    end

    def post(path, params=nil, headers=nil)
      req = Net::HTTP::Post.new(path)
      req.set_form_data(params) if params
      send_request(req, headers)
    end

    def multipart_post(path, params, headers=nil)
      req = Net::HTTP::Post::Multipart.new(path, params)
      send_request(req, headers)
    end

    private

    def send_request(request, headers)
      request['Accept'] = 'application/json'
      headers.each { |name, value| request[name] = value } if headers
      response = @http.request(request)
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
