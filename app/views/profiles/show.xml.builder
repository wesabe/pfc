xml.dasherize!
xml.instruct!
xml.profile do
  xml.name(@user.name)
  if @user == current_user
    xml.username(@user.username)
    xml.postal_code(@user.postal_code)
    xml.country(@user.cached_country.name, :id => @user.country_id) if @user.country_id
    xml.email(@user.email)
    xml.default_currency(@user.default_currency.name,
        :separator => @user.default_currency.separator,
        :delimiter => @user.default_currency.delimiter,
        :decimal_places => @user.default_currency.decimal_places,
        :symbol => @user.default_currency.unit) if @user.default_currency
    xml.joined(@user.created_at.utc.xmlschema)
    xml.filtered_tags(:type => "array") do
      @user.filter_tags.each do |ft|
        xml.tag do
          xml.name(ft.name)
        end
      end
    end
  end
end
