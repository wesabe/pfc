if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::MysqlAdapter.module_eval do
    def execute_with_retry_once(sql, name = nil)
      retried = false
      begin
        execute_without_retry_once(sql, name)
      rescue ActiveRecord::StatementInvalid => exception
        # just reraise the exception if we've already retried or this
        #   isn't a lost connection exception
        raise if retried || (exception.message !~ /Lost connection/)

        # Our database connection has gone away, reconnect and retry this method
        ActiveRecord::Base.logger.info "#{exception}, retried? #{retried}"
        reconnect!
        retried = true
        retry
      end
    end

    alias_method_chain :execute, :retry_once
  end
end