require "net/http"

module PokeApi
  # PokeAPI (https://pokeapi.co) の薄い HTTP クライアント
  class Client
    BASE_URL = "https://pokeapi.co/api/v2/".freeze
    MAX_RETRIES = 3

    class Error < StandardError; end
    class RetryableError < Error; end

    def initialize(base_url: BASE_URL, open_timeout: 5, read_timeout: 15)
      @base_url = base_url
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    # path は "pokemon/25" のような相対パスでも、レスポンスに含まれる完全な URL でもよい
    def get(path, **params)
      uri = URI.join(@base_url, path)
      uri.query = URI.encode_www_form(params) if params.any?

      with_retries(uri) do
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                   open_timeout: @open_timeout, read_timeout: @read_timeout) do |http|
          http.request(Net::HTTP::Get.new(uri, "Accept" => "application/json"))
        end

        case response
        when Net::HTTPSuccess then JSON.parse(response.body)
        when Net::HTTPNotFound then raise Error, "Not found: #{uri}"
        else raise RetryableError, "HTTP #{response.code}: #{uri}"
        end
      end
    end

    private

    def with_retries(uri)
      attempts = 0
      begin
        attempts += 1
        yield
      rescue RetryableError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET => e
        raise Error, "#{e.class}: #{e.message} (#{uri})" if attempts >= MAX_RETRIES

        sleep(2**attempts)
        retry
      end
    end
  end
end
