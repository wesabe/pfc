# Adds SQL sanitization options to AR connections:
#
#   ActiveRecord::Base.connection.select_one(["select * from a_table where id = ?", 300])
#
# This applies to select_one, select_all, execute, insert, update, and delete.
if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  class ActiveRecord::ConnectionAdapters::MysqlAdapter

    def execute_with_sanitization(sql, name = nil)
      execute_without_sanitization(sanitize(sql), name)
    end
    alias_method_chain :execute, :sanitization

  private

    def select_with_sanitization(sql, name = nil)
      select_without_sanitization(sanitize(sql), name)
    end
    alias_method_chain :select, :sanitization

    def sanitize(sql)
      ActiveRecord::Base.instance_eval{ sanitize_sql(sql, nil) }
    end

  end
end