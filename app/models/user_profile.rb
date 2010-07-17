class UserProfile < ActiveRecord::Base
  belongs_to :user
  before_save :website_protocol_check

  attr_accessible :website

private

  def website_protocol_check
    return self.website = nil if website.blank?

    begin
      uri = URI.parse(website)
      case uri.scheme
      when 'http', 'https'
        self.website = uri.to_s
      when nil
        self.website = "http://#{uri}"
      else
        raise URI::InvalidURIError, "#{website.inspect} is not an HTTP/HTTPS URI"
      end
    rescue URI::InvalidURIError => e
      logger.warn "Discarding invalid URI #{website.inspect} for user #{user.uid} because: #{e.message}"
      self.website = nil
    end
  end
end
