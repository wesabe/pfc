require 'net/https'

module Net
  class HTTP
    class <<self
      def get_response(uri_or_host, path=nil, port=nil, &block)
        if path
          host = uri_or_host
          new(host, port || HTTP.default_port).start {|http|
            return http.request_get(path, &block)
          }
        else
          uri = uri_or_host
          http = new(uri.host, uri.port)
          http.use_ssl = (uri.scheme=='https')
          return http.request_get(uri.fullpath, &block)
        end
      end
    end
  end

  if RUBY_VERSION < "1.8.7"
    # No, seriously. 1K buffer is not enough.
    class BufferedIO
    private
      BUFSIZE = 1024 * 16

      def rbuf_fill
        timeout(@read_timeout) {
          @rbuf << @io.sysread(BUFSIZE)
        }
      end

    end
  end
end