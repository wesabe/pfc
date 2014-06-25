require 'csv'

namespace :stocks do
  task :import => :environment do
    SOURCES = [
      { :name => "AMEX",
        :exchange => "AMEX",
        :url => "http://www.nasdaq.com//asp/symbols.asp?exchange=1&start=0",
        :header_lines => 2 },
      { :name => "NASDAQ",
        :exchange => "NASDAQ",
        :url => "http://www.nasdaq.com//asp/symbols.asp?exchange=Q&start=0",
        :header_lines => 2 },
      { :name => "NYSE",
        :exchange => "NYSE",
        :url => "http://www.nasdaq.com//asp/symbols.asp?exchange=N&start=0",
        :header_lines => 2 },
      { :name => "EFT and Closed End Funds",
        :exchange => nil,
        :url => "http://www.masterdata.com/Downloads/MasterfileETFs.csv",
        :header_lines => 1 }
    ]
    record_count = 0
    Stock.transaction do
      SOURCES.each do |data|
        puts "Downloading #{data[:name]} data..." if ENV['VERBOSE']
        response = Net::HTTP::Proxy(HTTP_PROXY_HOST, HTTP_PROXY_PORT,
                                    HTTP_PROXY_USER, HTTP_PROXY_PASS).get_response(URI.parse(data[:url]))
        raise "Failed to get #{data[:url]}; response code: #{response.code}" if response.code != '200'

        fcsv = CSV.new(response.body)
        data[:header_lines].times { fcsv.readline } # get rid of header rows
        while true
          begin
            row = fcsv.readline || break
            (name, symbol) = row[0..1]
            next if symbol.blank?
            symbol.gsub!(/[\/^]/,'.') # convert to standard dotted format
            symbol.gsub!(/\.+$/,'') # we don't care about these extra tickers
            Stock.create!(:name => name, :symbol => symbol, :exchange => data[:exchange])
            record_count += 1
            puts "Added #{data[:exchange]} - #{name} (#{symbol})" if ENV['VERBOSE']
          rescue ActiveRecord::StatementInvalid => ex
            if ex.message =~ /Duplicate entry/
              puts "Ignoring duplicate: #{symbol}" if ENV['VERBOSE']
            else
              raise
            end
          rescue CSV::MalformedCSVError => ex
            raise unless ex.message =~ /Illegal quoting|Unclosed quoted field/
          end
        end
      end
    end
    puts "Imported #{record_count} new records." if ENV['VERBOSE']
  end
end
