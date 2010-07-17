# Preload the Financial Institutions cache used by the uploader drop-downs.
require 'mysql'
begin FinancialInst.popular_names(200) rescue Mysql::Error end