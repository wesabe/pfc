module Api::Constants
  CURRENT_UPLOADER_VERSION = "1.0.30"
  CURRENT_API_VERSION = "1.0.30"
  OLDEST_SUPPORTED_API_VERSION = "0.7.0"

  module Error
    VERSION =
      {:code => 1,
       :message => "There is a new version of the Uploader available. Please visit the Wesabe site to download the latest release."}
    FORMAT_CHANGE_OFX_TO_QIF =
      {:code => 2,
       :message => "You are attempting to upload an QIF format to an account to which you previously uploaded OFX/QFX. Mixing formats is not currently supported and will likely result in duplicate transactions."}
    FORMAT_CHANGE_QIF_TO_OFX =
      {:code => 3,
       :message => "You are attempting to upload an OFX/QFX format to an account to which you previously uploaded QIF. Mixing formats is not currently supported and will likely result in duplicate transactions."}
    UNSUPPORTED_STATEMENT_TYPE =
      {:code => 4,
       :message => "You have attempted to upload a statement type that we do not yet support. We currently support bank and credit card statements; we do not yet support investment accounts."}
    IMPORT_FAILED =
      {:code => 5,
       :message => "There was an error importing the statement."}
    UNSUPPORTED_UPLOADER_VERSION =
       {:code => 6,
        :message => "The Uploader version you are using is no longer supported. Please visit the Wesabe site to download the latest release."}
  end
end