class ::ActiveRecord::ConnectionAdapters::MysqlAdapter
  def native_database_types_with_string_passthrough
    Hash.new do |hash, key|
      hash[key] = { :name => key }
    end.update(native_database_types_without_string_passthrough)
  end
  alias :native_database_types_without_string_passthrough :native_database_types
  alias :native_database_types :native_database_types_with_string_passthrough
end