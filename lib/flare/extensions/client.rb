module RSolr
  class Client

    alias :old_build_request :build_request
    
    def build_request path, opts
      o = old_build_request(path, opts)
      [:verify_mode].each { |k| o[k] = @options[k] }
      o
    end
  end
end