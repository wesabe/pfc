require 'uri'
require 'yaml'

class Service
  attr_reader :base_uri, :auth_scheme

  def initialize(base_uri, auth_scheme=nil)
    case base_uri
    when String
      base_uri += '/' unless base_uri.ends_with?('/')
      @base_uri = URI.parse(base_uri)
    when nil
      raise ArgumentError, "base URI cannot be nil"
    else
      @base_uri = base_uri
    end

    @auth_scheme = auth_scheme
  end

  def get(path, &block)
    request :get, path, &block
  end

  def post(path, params, &block)
    request :post, path, params, &block
  end

  def put(path, params, &block)
    request :put, path, params, &block
  end

  def delete(path, &block)
    request :delete, path, &block
  end

  def request(method, path, params={}, &block)
    request_for(path, params, &block).__send__(method.to_s.downcase)
  end

  private

  def request_for(path, params={})
    # strip leading slashes for URI#+
    path = path[1..-1] if path.starts_with?('/')

    Request.new(@base_uri + path) do |req|
      req.auth_scheme = auth_scheme if auth_scheme
      req.params = params
      yield req if block_given?
    end
  end

  def self.get(name)
    named_config = config[name] || config[:default]
    new(named_config[:uri], named_config[:auth_scheme])
  end

  def self.config
    @config ||= begin
      config_path = Rails.root.join('config/services.yml')
      YAML.load_file(config_path).with_indifferent_access[Rails.env]
    end
  end

  def self.logger
    Rails.logger
  end

  class Request
    attr_reader   :uri, :headers
    attr_accessor :timeout, :retries,
                  :user, :auth_scheme,
                  :proxy_url, :params

    def initialize(uri)
      # set defaults
      @headers     = {}
      @proxy_url   = nil # disable proxy
      @retries     = 2
      @auth_scheme = 'Basic'
      @params      = {}

      yield self if block_given?

      @uri = uri
    end

    def get
      perform :get
    end

    def put
      perform :put
    end

    def post
      perform :post
    end

    def delete
      perform :delete
    end

    private

    def perform(method)
      retries   = @retries
      old_proxy = RestClient.proxy
      res       = nil

      begin
        RestClient.proxy = proxy_url.blank?? nil : proxy_url
        res = [:put, :post].include?(method) ? resource.__send__(method, params) : resource.__send__(method)
      rescue RestClient::Exception => e
        if retries > 0
          Service.logger.warn { ["#{e.class}: #{e.message}", *e.backtrace].join("\n") }
          retries -= 1
          retry
        else
          # return error response
          Service.logger.error { ["#{e.class}: #{e.message}", *e.backtrace].join("\n") }
          res = e.response
        end
      ensure
        RestClient.proxy = old_proxy
      end

      return Response.new(res.code, res.headers, res.body, res.headers[:content_type]) if res
    end

    def resource
      RestClient::Resource.new(uri.to_s,
        :timeout => timeout.to_i,
        :headers => headers_for_rest_client
      )
    end

    def headers_for_rest_client
      headers = @headers.dup
      headers[:accept] ||= 'application/json'
      headers['Authorization'] ||= "#{auth_scheme} #{["#{user.id}:#{user.account_key}"].pack("m").strip.gsub("\n", "")}" if user
      return headers
    end
  end

  class Response
    attr_reader :code, :headers, :body, :content_type

    def initialize(code, headers, body, content_type)
      @code, @headers, @body, @content_type = code, headers, body, content_type
    end

    def self.error(sym)
      case sym
      when :gateway_timeout
        Response.new(504, "Gateway Timeout", "", "text/plain")
      else
        Response.new(500, "Internal Server Error", "", "text/plain")
      end
    end
  end
end
