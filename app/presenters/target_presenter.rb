class TargetPresenter < SimplePresenter
  def as_json(*)
    {
      :tag => {
        :name => tag_name
      },
      :monthly_limit => Money.new(amount_per_month, currency).as_json,
      :amount_spent => Money.new(amount_spent, currency).as_json
    }
  end

  def to_json
    as_json.to_json
  end

  private

  def currency
    controller.current_user.default_currency
  end
end
