# Add session data to log file
# Usage:
#   SESSION_DEBUG=key1,key2 script/server
#     display values of session data keys :key1 and :key2 with each request
#   SESSION_DEBUG=1 script/server - 
#     display all session data keys and values with each request
if !ENV['SESSION_DEBUG'].blank?
  class ActionController::Base
  private
    def log_processing_with_session_debug
      log_processing_without_session_debug
      return unless logger
      log_msg = "  Session data: "
      if ENV['SESSION_DEBUG'] == '1'
        log_msg << @_session.data.inspect
      else
        keys = ENV['SESSION_DEBUG'].split(',')
        # stupidly, Hash#select returns an array instead of a hash
        log_msg << @_session.data.reject {|k,v| !keys.include? k.to_s}.inspect
      end
      logger.info(log_msg)
    end
    alias_method_chain :log_processing, :session_debug
  end
end
