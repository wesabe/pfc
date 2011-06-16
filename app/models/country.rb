class Country < ActiveRecord::Base
  # Returns an array of name/id tuples for all countries. Suitable for use with
  # the +select+ helper.
  #
  #     <%= select :user, :country_id, Country.ids_and_names %>
  def self.ids_and_names
    select(:id, :name).order(:name).map { |country| [country.name, country.id] }
  end

  def self.us
    Country.find_by_code("us") || Country.create(:code => "us", :name => "United States of America", :currency => "USD")
  end

  # override AR method so we can return a currency object
  def currency
    begin
      Currency.new(read_attribute('currency'))
    rescue Currency::UnknownCurrencyException
      Currency.new('USD')
    end
  end

  # override default_time_zone so we can return a TimeZone object
  def default_time_zone
    tz = read_attribute('default_time_zone')
    ActiveSupport::TimeZone.new(tz) if tz
  end
end
