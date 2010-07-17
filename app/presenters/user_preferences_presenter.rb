class UserPreferencesPresenter < SimplePresenter
  def to_json
    export_data.to_json
  end

  def export_data
    (preferences || {}).
      reject {|k,| system_attr?(k)}.
      merge(:default_currency => default_currency).
      merge(:features => tester_access)
  end

  def default_currency
    currency = user.default_currency
    return {
      :name => currency.name, :unit => currency.unit,
      :delimiter => currency.delimiter, :separator => currency.separator,
      :precision => currency.decimal_places
    }
  end
end
