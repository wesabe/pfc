module DataPreloading
  def preload_accounts
    _preload_url_into(
      "/accounts/all/#{current_user.default_currency}?include_archived=true",
      'wesabe.data.accounts.sharedDataSource.setData')
  end

  def preload_tags
    _preload_url_into(
      "/analytics/summaries/tags/all/#{current_user.default_currency}",
      'wesabe.data.tags.sharedDataSource.setData')
  end

  def preload_credentials
    _preload_data(
      current_user.account_creds,
      "wesabe.data.credentials.sharedDataSource.setData")
  end

  private

  def _preload_url_into(url, setter)
    res = Service.get(:brcm).get(url) do |req|
      req.user = current_user
      req.timeout = 5.seconds
      req.headers['Accept'] = 'application/json'
    end

    _preload_data(ActiveSupport::JSON.decode(res.body), setter) if res && res.code == 200
  end

  def _preload_data(data, setter)
    content_for :footer do
      <<-HTML
<script type="text/javascript">
  wesabe.ready("#{setter}", function() {
    #{setter}(#{ActiveSupport::JSON.encode(data)});
  });
</script>
      HTML
    end
  end
end