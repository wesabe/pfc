# Importer holds methods used to import raw upload data into the database
class Importer
  class UnsupportedStatementType < Exception; end
  class XMLParseException < Exception; end

  #----------------------------------------------------------------
  # Public Class Methods
  #

  # extract the data from the request, create an Upload object, and import it
  def self.import_request(user, request, account_cred_id = nil)
    data = fix_line_endings(request.env['RAW_POST_DATA'])

    # check content length
    raise RequestSizeExceeded if data.size > ApiEnv::MAX_UPLOAD_SIZE

    upload = generate_upload_from_raw_post(user, data, account_cred_id)

    # extract the client info from the request
    match = request.user_agent.match(%r{^(.*?)/(\S+)\s+\((.*?)\)})
    upload.client_name = match ? match[1] : request.user_agent
    upload.client_version = match ? match[2] : nil
    client_platform = match ? match[3] : 'UNKNOWN'
    upload.client_platform = ClientPlatform.find_or_create_by_name(client_platform)

    import(upload)
  end

  # convert Windows & Mac line endings to Unix
  def self.fix_line_endings(data)
    data.gsub(/\r+\n?/m, "\n")
  end

  # parse the raw post into an xml document and create an upload object to send to the importer
  def self.generate_upload_from_raw_post(user, data, account_cred_id = nil)
    xml = REXML::Document.new(data)

    upload_node = xml.elements["/upload"]
    statement_node = xml.elements["/upload/statement"]

    # make sure balance doesn't have non-numeric characters
    balance = Currency.normalize(statement_node.attributes["balance"])

    # if accttype is CREDITCARD, chances are the balance that the user
    # entered is positive, when it should be negative. fix that
    accttype = statement_node.attributes["accttype"]
    if balance && accttype == "CREDITCARD"
      balance = balance.to_f
      balance = -balance if balance > 0
      balance = balance.to_s
    end

    raise "BlankWesabeId" if statement_node.attributes["wesabe_id"] == ''

    Upload.generate(:user => user,
               :raw_request => data,
               :statement => statement_node.text,
               :wesabe_id => statement_node.attributes["wesabe_id"],
               :account_number => statement_node.attributes["acctid"],
               :account_type => accttype,
               :balance => balance,
               :original_format => statement_node.attributes["format"],
               :account_cred_id => account_cred_id,
               :bulk_update => true)
  end

  def self.import(upload) #user, upload, ofx_data)
    # REVIEW: not sure where the best place to save the upload is
    upload.save!

    # import the OFX 2.0 output into the database
    begin
      if upload.investment_statement?
        OFX::InvestmentStatement.import(upload)
      else
        OFX2Importer.import(upload)
      end
    rescue OFX2Importer::UnsupportedStatementType
      # FIXME: this is repetitive...DRY this up later
      raise UnsupportedStatementType
    rescue OFX2Importer::XMLParseException => e
      raise XMLParseException, e.message, e.backtrace
    end
  end
end
