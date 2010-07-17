class AccountPresenter < SimplePresenter
  def export_data
    data = {
      :uri => account_path(self),
      :name => name,
      :type => account_type.name,
      :position => position,
      :currency => currency.name,
      :status => Constants::Status.string_for(status).downcase
    }
    if balance
      data.update(
        :balance => {
          :display => Money.new(balance, currency).to_s,
          :value => balance
        },
        :last_balance_at => last_balance && last_balance.created_at)
    end

    return data
  end

  def to_json
    export_data.to_json
  end
end
