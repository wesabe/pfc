# base class for any transaction export formats
class Exporter::Txaction < Exporter

  def initialize(user, data, options = {})
    @user = user # authenticated user
    if data.is_a?(String) # if we get a string, assume it is JSON that needs decoding
      @data = ActiveSupport::JSON.decode(data)
    else
      @data = data
    end
    @options = options
  end

  private

  # given a relative account id, load the Account for the given authenticated user
  def find_account(id)
    (@accounts ||= {})[id] ||= @user.accounts.visible.find_by_id_for_user(id)
  end
end
