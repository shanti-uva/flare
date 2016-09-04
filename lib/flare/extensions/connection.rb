module RSolr
  class Connection
    
    alias :old_execute :execute
    
    # Same as original, except adding verify_mode to http call from request_context
    def execute client, request_context
      h = http request_context[:uri], request_context[:proxy], request_context[:read_timeout], request_context[:open_timeout], request_context[:verify_mode]
      request = setup_raw_request request_context
      request.body = request_context[:data] if request_context[:method] == :post and request_context[:data]
      begin
        response = h.request request
        charset = response.type_params["charset"]
        {:status => response.code.to_i, :headers => response.to_hash, :body => force_charset(response.body, charset)}
      rescue Errno::ECONNREFUSED
        raise RSolr::Error::ConnectionRefused, request_context.inspect
      # catch the undefined closed? exception -- this is a confirmed ruby bug
      rescue NoMethodError => e
        e.message == "undefined method `closed?' for nil:NilClass" ?
          raise(RSolr::Error::ConnectionRefused, request_context.inspect) :
          raise(e)
      end
    end
    
    protected
    
    alias :old_http :http

    # This returns a singleton of a Net::HTTP or Net::HTTP.Proxy request object.
    def http uri, proxy = nil, read_timeout = nil, open_timeout = nil, verify_mode = nil
      h = old_http(uri, proxy, read_timeout, open_timeout)
      h.verify_mode = verify_mode
      h
    end
  end
end