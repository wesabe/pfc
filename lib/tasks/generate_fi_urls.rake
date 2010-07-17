

desc "generate a list of fi urls to import into financial_insts table"
task :generate_fi_urls => :environment do |t|
  include ActiveRecord::ConnectionAdapters::Quoting
  
    data_dir = "#{RAILS_ROOT}/../../python/uploader/resources/detail"
    sql = ''
    for fi in FinancialInst.find(:all)
      begin
        data = File.read("#{data_dir}/#{fi.fipid}.xml")
        if m = data.match(/<website>(.*?)<\/website>/) then fi.website = m[1]; end
        if m = data.match(/<stmtsite>(.*?)<\/stmtsite>/) then fi.stmtsite = m[1]; end
        sql << "update financial_insts set website = #{quote_value(fi.website)} where id = #{fi.id};\n" if fi.website
        sql << "update financial_insts set stmtsite = #{quote_value(fi.stmtsite)} where id = #{fi.id};\n" if fi.stmtsite
      rescue Errno::ENOENT
        # file not found; ignore
      end
    end
    open("#{RAILS_ROOT}/db/bootstrap/fi_urls.sql",'w') {|f| f.puts(sql) }
end