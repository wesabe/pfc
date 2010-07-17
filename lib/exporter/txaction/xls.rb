require 'exporter/txaction/csv'

class Exporter::Txaction::Xls < Exporter::Txaction::Csv
  def content_type
    "application/vnd.ms-excel"
  end

  def initialize(user, data, options = {})
    super(user, data, options.reverse_merge(:col_sep => "\t"))
  end
end