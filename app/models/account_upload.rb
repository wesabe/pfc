class AccountUpload < ActiveRecord::Base
  set_table_name :accounts_uploads
  belongs_to :account
  belongs_to :upload

  # override destroy because stupid AR expects an id column
  def destroy
    _run_destroy_callbacks do
      upload.destroy_for_account(account) if upload && account
      true
    end
  end
end