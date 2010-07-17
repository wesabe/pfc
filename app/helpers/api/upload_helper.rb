module Api::UploadHelper
  include Api::Constants

  # extract api version from User-Agent string
  def get_api_version(user_agent)
    logger.debug("user agent: #{user_agent}")
    match = user_agent.match(%r{Wesabe-API/(\S+)})
    return match ? match[1] : ""
  end

  def get_desktop_uploader_version(user_agent)
    match = user_agent.match(%r{Wesabe-Uploader/(\S+)})
    return match ? match[1] : ""
  end

  # return true if the uploader version is compatible with the api
  def compatible_version?(version)
    return version.version_to_i >= Api::Constants::OLDEST_SUPPORTED_API_VERSION.version_to_i
  end

  # return true if the uploader version is the most recent (use >= just in case the
  # CURRENT_UPLOADER_VERSION constant falls behind the actual current uploader version
  def most_recent_version?(version)
    return version.version_to_i >= Api::Constants::CURRENT_UPLOADER_VERSION.version_to_i
  end

end
