require 'net/http'
require 'uri'
require 'openssl'
require 'sidekiq'

ENV['http_proxy'] = 'http://127.0.0.1:8080'

Sidekiq.configure_server do |config|
  config.logger.level = Logger::WARN
  config.log_formatter = Sidekiq::Logger::Formatters::JSON.new
end

if !File.exists?(ARGV[0])
  raise "File doesn't exist"
end

@method = ARGV[1] || 'GET'

class SQRequest < Net::HTTPRequest
  REQUEST_HAS_BODY  = false
  RESPONSE_HAS_BODY = true
end

SQRequest::METHOD = @method

class Jobless
  include Sidekiq::Worker

  def perform(url)
    uri = URI.parse(url)
    request = SQRequest.new(uri)
    request.content_type = "application/x-www-form-urlencoded"
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:84.0) Gecko/20100101 Firefox/84.0"
    request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    request["Accept-Language"] = "en-US,en;q=0.5"
    request["Authorization"] = "Bearer -"
    # request["Content-Length"] = "169"
    request["Origin"] = "http://pingb.in/"
    request["Connection"] = "keep-alive"
    request["Referer"] = "http://pingb.in/"
    request["Upgrade-Insecure-Requests"] = "1"
    # request.set_form_data(
    #   "password" => "",
    #   "username" => "",
    # )

    req_options = {
      use_ssl: uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    # response.each_header do |header, values|
    #   puts "\t#{header}: #{values.inspect}"
    # end

    puts [@method, url, response.code].join(' ')
    # response.body
  end
end

# main

def load_urls_from_file(name)
  file = File.open(name)
  urls = file.readlines.map(&:chomp)
  file.close

  return urls
end

urls = load_urls_from_file(ARGV[0])

urls.each do |url|
  Jobless.perform_async(url)
end
