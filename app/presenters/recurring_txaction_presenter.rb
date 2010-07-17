class RecurringTxactionPresenter < SimplePresenter
  def export_data
    {
      :merchant_name => merchant.name,
      :merchant_id => merchant.id,
      :amount => amount,
      :potential_savings => formatted_potential_savings,
      :next_charge => estimated_next_charge,
      :last_date_posted => last_date_posted.strftime("%Y-%m-%d"),
      :first_date_posted => first_date_posted.strftime("%Y-%m-%d")
    }
  end

  def to_json
    export_data.to_json
  end
end
