require 'rest_client'

# Respresents a snapshot on another instance of Wesabe and allows you to easily
# import a user from from it using the same email and password used remotely.
#
#    snapshot = RemoteSnapshot.new('www.wesabe.com', 'me@example.com', 'fe5jx309m')
#    snapshot.import # => #<User id: 1, username: "me@example.com", ...>
#
class RemoteSnapshot
  attr_reader :host, :email, :password, :options

  def initialize(host, email, password, options={})
    @host, @email, @password, @options = host, email, password, options

    raise ArgumentError, "host is required" if host.nil?
    raise ArgumentError, "email is required" if email.nil?
    raise ArgumentError, "password is required" if password.nil?
  end

  def import
    ensure_ready
    Importer::Wesabe.import(download, options.merge(:password => password))
  end

  def import!
    build
    import
  end

  def self.import(host, email, password, options={})
    new(host, email, password, options).import
  end

  def self.import!(host, email, password, options={})
    new(host, email, password, options).import!
  end

  def ensure_ready
    if not ready?
      build unless building?
      sleep 1 until ready?
    end
  end

  def build
    post
  end

  def building?
    return false if ready?
    value_at('snapshot') != nil
  end

  def ready?
    value_at('snapshot/ready') == true
  end

  def uid
    value_at('snapshot/uid')
  end

  def download
    TempfilePath.generate.tap do |path|
      path.open('w') {|f| f << get(:zip) }
    end
  end

  private

  def value_at(path)
    path.split('/').inject(get) do |value, key|
      value[key] if value
    end
  end

  def get(format=:json)
    response = resource.get(:accept => format)

    case format
    when :json
      ActiveSupport::JSON.decode(
        response.                       # strip the secure comment: /*-secure- {"snapshot": ...} */
          sub(%r{^/\*-secure-\s*}, '').
          sub(%r{\s*\*/$}, ''))
    else
      response
    end
  end

  def post(format=:json, &block)
    resource.post(:accept => format, &block)
  end

  def resource
    @resource ||= RestClient::Resource.new("https://#{host}/snapshot", email, password)
  end
end