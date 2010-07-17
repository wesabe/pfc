# KILL IT
# KILL IT
# KILL IT WITH FIRE
# WJW
class CGI::Session
    # WHAT THE **FUCK** MATZ
    # SERIOUSLY WHAT THE SHIT
    def initialize(request, option={})
      @new_session = false
      session_key = option['session_key'] || '_session_id'
      session_id = option['session_id']
      unless session_id
	if option['new_session']
	  session_id = create_new_id
	end
      end
      unless session_id
	if request.key?(session_key)
	  session_id = request[session_key]
	  session_id = session_id.read if session_id.respond_to?(:read)
	end
	unless session_id
	  session_id, = request.cookies[session_key]
	end
	unless session_id
	  unless option.fetch('new_session', true)
	    raise ArgumentError, "session_key `%s' should be supplied"%session_key
	  end
	  session_id = create_new_id
	end
      end
      @session_id = session_id
      dbman = option['database_manager'] || FileStore
      begin
        @dbman = dbman::new(self, option)
      rescue NoSession
        unless option.fetch('new_session', true)
          raise ArgumentError, "invalid session_id `%s'"%session_id
        end
        session_id = @session_id = create_new_id
        retry
      end
      request.instance_eval do
	@output_hidden = {session_key => session_id} unless option['no_hidden']
	@output_cookies =  [
          CGI::Cookie::new("name" => session_key,
		      "value" => session_id,
		      "expires" => option['session_expires'],
		      "domain" => option['session_domain'],
		      # I AM SO FUCKING THRILLED TO BE USING SUCH AN EXTENSIBLE LANGUAGE
		      "http_only" => option["session_http_only"],
		      # IT MAKES ME FEEL WARM AND HAPPY INSIDE AND NOT AT ALL LIKE DYING
		      "secure" => option['session_secure'],
		      "path" => if option['session_path'] then
				  option['session_path']
		                elsif ENV["SCRIPT_NAME"] then
				  File::dirname(ENV["SCRIPT_NAME"])
				else
				  ""
				end)
        ] unless option['no_cookies']
      end
      @dbprot = [@dbman]
      # YOU HAVE GOT TO BE FUCKING KIDDING ME
      ObjectSpace::define_finalizer(self, CGI::Session::callback(@dbprot))
    end
end