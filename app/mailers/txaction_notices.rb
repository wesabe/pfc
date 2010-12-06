class TxactionNotices < ActionMailer::Base
  default :from => "watchdog@mesabe.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.txaction_notices.too_big.subject
  #
  def too_big(txaction)
    @txaction = txaction
    @account  = @txaction.account
    @user     = @account.user

    mail :to => @user.email
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.txaction_notices.duplicate.subject
  #
  def duplicate(duplicate, original)
    @duplicate = duplicate
    @original  = original
    @account   = @duplicate.account
    @user      = @account.user

    mail :to => @user.email
  end
end
