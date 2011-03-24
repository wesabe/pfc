class UseReverseDnsForFiWesabeIds < ActiveRecord::Migration
  MAPPING = {"ca-000101" => "com.vancity",
             "ca-000102" => "com.myvisaaccount",
             "fr-000102" => "net.bnpparibas",
             "uk-000100" => "uk.co.hsbc",
             "uk-000111" => "uk.co.nationwide",
             "uk-000113" => "com.first-direct",
             "us-000169" => "org.texanscu",
             "us-000238" => "com.bankofamerica",
             "us-000563" => "com.mechdirect",
             "us-000618" => "com.cnbt",
             "us-000641" => "com.schwab.bank",
             "us-000678" => "com.nationalcity",
             "us-000840" => "com.usaa",
             "us-000859" => "com.usbank",
             "us-000953" => "com.cypruscu",
             "us-001034" => "com.citibank",
             "us-001069" => "com.wamu",
             "us-001201" => "com.huntington",
             "us-001343" => "com.wellsfargo",
             "us-001409" => "com.capitalone.credit",
             "us-001585" => "com.capitalone.bank",
             "us-001659" => "com.paypal",
             "us-001758" => "com.wachovia",
             "us-001784" => "com.missionfed",
             "us-002337" => "com.everbank",
             "us-002400" => "com.addisonavenue",
             "us-002551" => "com.discovercard",
             "us-002697" => "org.starone",
             "us-003215" => "com.firstmarketbank",
             "us-003243" => "com.ingdirect",
             "us-003274" => "com.psecu",
             "us-003383" => "com.americanexpress",
             "us-003396" => "com.chase",
             "us-003429" => "com.tdcanadatrust",
             "us-003850" => "com.etrade",
             "us-003971" => "com.hsbc",
             "us-004273" => "com.wamu.credit",
             "us-008273" => "com.smartypig",
             "us-015635" => "com.deltacommunitycu"}.freeze
   
  def self.up
    change_column :financial_insts, :wesabe_id, :string, :limit => nil
    map_wesabe_ids MAPPING
  end

  def self.down
    map_wesabe_ids MAPPING.invert
  end
  
  def self.map_wesabe_ids(mapping)
    mapping.each do |old, new|
      fi = FinancialInst.find_public(old)
      if fi.nil?
        puts "~ #{old} not found"
      else
        puts "~ #{old} -> #{new}"
        fi.update_attribute(:wesabe_id, new)
      end
    end
  end
end
