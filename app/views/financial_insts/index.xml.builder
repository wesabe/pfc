xml.instruct!
xml.instance_eval { @indent = 0 } # this is ugly, but it's also going to save us about 140K in whitespace
xml.tag!("financial-insts") do
  @financial_insts.each do |fi|
    xml.tag!("financial-inst") do
      xml.tag!("name",            fi.name)
      xml.tag!("login-url",       fi.login_url )
      xml.tag!("homepage-url",    fi.homepage_url)
      xml.tag!("wesabe-id",       fi.wesabe_id)
      xml.tag!("connection-type", fi.connection_type)
      if fi.account_number_regex.present?
        xml.tag!("account-number-regex") { xml.cdata!(fi.account_number_regex) }
      end
    end
  end
end