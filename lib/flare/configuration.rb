require 'erb'
require 'yaml'

module Flare #:nodoc:
  #
  # Flare::Configuration is configured via the config/flare.yml file, which
  # contains properties keyed by environment name. A sample flare.yml file
  # would look like:
  #
  #   development:
  #     solr:
  #       hostname: localhost:8982
  #       min_memory: 512M
  #       max_memory: 1G
  #       solr_jar: /some/path/solr15/start.jar
  #       bind_address: 0.0.0.0
  #     disabled: false
  #   test:
  #     solr:
  #       hostname: localhost:8983
  #       log_level: OFF
  #       open_timeout: 0.5
  #       read_timeout: 2
  #   production:
  #     solr:
  #       scheme: http
  #       user: username
  #       pass: password
  #       hostname: localhost:8983
  #       path: /solr/myindex
  #       log_level: WARNING
  #       solr_home: /some/path
  #       open_timeout: 0.5
  #       read_timeout: 2
  #     auto_index_callback: after_commit
  #     auto_remove_callback: after_commit
  #     auto_commit_after_request: true
  #
  # Flare::Configuration uses the configuration to set up the Solr connection.
  #
  class Configuration
    # ActiveSupport log levels are integers; this array maps them to the
    # appropriate java.util.logging.Level constant
    LOG_LEVELS = %w(FINE INFO WARNING SEVERE SEVERE INFO)
    VERIFY_MODES = {VERIFY_NONE: OpenSSL::SSL::VERIFY_NONE, VERIFY_PEER: OpenSSL::SSL::VERIFY_PEER, VERIFY_CLIENT_ONCE: OpenSSL::SSL::VERIFY_CLIENT_ONCE, VERIFY_FAIL_IF_NO_PEER_CERT: OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT}
    
    #attr_writer :user_configuration
    
    def initialize(path: nil, hostname: nil)
      @path_key = path.blank? ? 'path' : path
      @hostname_key = hostname.blank? ? 'hostname' : hostname
    end
    
    #
    # The host name at which to connect to Solr. Default 'localhost'.
    #
    # ==== Returns
    #
    # String:: host name
    #
    def hostname
      unless defined?(@hostname)
        @hostname   = solr_url.host if solr_url
        @hostname ||= configuration_from_key('solr', @hostname_key)
        @hostname ||= default_hostname
      end
      @hostname
    end
    
    #
    # The scheme to use, http or https.
    # Defaults to http
    #
    # ==== Returns
    #
    # String:: scheme
    #
    def scheme
      unless defined?(@scheme)
        @scheme   = solr_url.scheme if solr_url
        @scheme ||= configuration_from_key('solr', 'scheme')
        @scheme ||= default_scheme
      end
      @scheme
    end
    
    #
    # The verify_mode to use.
    #
    def verify_mode
      unless defined?(@verify_mode)
        str = configuration_from_key('solr', 'verify_mode')
        @verify_mode = str.blank? ? nil : VERIFY_MODES[str.to_sym]
      end
      @verify_mode
    end
    
    #
    # The userinfo used for authentication, a colon-delimited string like "user:pass"
    # Defaults to nil, which means no authentication
    #
    # ==== Returns
    #
    # String:: userinfo
    #
    def userinfo
      unless defined?(@userinfo)
        @userinfo   = solr_url.userinfo if solr_url
        user = configuration_from_key('solr', 'user')
        pass = configuration_from_key('solr', 'pass')
        @userinfo ||= [ user, pass ].compact.join(":") if user && pass
        @userinfo ||= default_userinfo
      end
      @userinfo
    end
    
    #
    # The url path to the Solr servlet (useful if you are running multicore).
    # Default '/solr/default'.
    #
    # ==== Returns
    #
    # String:: path
    #
    def path
      unless defined?(@path)
        @path   = solr_url.path if solr_url
        @path ||= configuration_from_key('solr', @path_key)
        @path ||= default_path
      end
      @path
    end
    
    #
    # Specifies the number of seconds to delay the indexer job if in business hours.
    #
    # ==== Returns
    #
    # String:: delay_if_business_hours
    #
    def delay_if_business_hours
      unless defined?(@delay_if_business_hours)
        value = configuration_from_key('solr', 'delay_if_business_hours')
        if value.blank?
          @delay_if_business_hours = nil
        else
          @delay_if_business_hours = value.to_i
        end
      end
      @delay_if_business_hours
    end
    
    #
    # The default log_level that should be passed to solr. You can
    # change the individual log_levels in the solr admin interface.
    # If no level is specified in the sunspot configuration file,
    # use a level similar to Rails own logging level.
    #
    # ==== Returns
    #
    # String:: log_level
    #
    def log_level
      @log_level ||= configuration_from_key('solr', 'log_level')
      @log_level ||= LOG_LEVELS[::Rails.logger.level]
    end
    
    #
    # Should the solr index receive a commit after each http-request.
    # Default true
    #
    # ==== Returns
    #
    # Boolean: auto_commit_after_request?
    #
    def auto_commit_after_request?
      @auto_commit_after_request ||= (configuration_from_key('auto_commit_after_request') != false)
    end
    
    #
    # As for #auto_commit_after_request? but only for deletes
    # Default false
    #
    # ==== Returns
    #
    # Boolean: auto_commit_after_delete_request?
    #
    def auto_commit_after_delete_request?
      @auto_commit_after_delete_request ||= (configuration_from_key('auto_commit_after_delete_request') || false)
    end
    
    #
    # The log directory for solr logfiles
    #
    # ==== Returns
    #
    # String:: log_dir
    #
    def log_file
      @log_file ||= (configuration_from_key('solr', 'log_file') || default_log_file_location )
    end
    
    def data_path
      @data_path ||= configuration_from_key('solr', 'data_path') || File.join(::Rails.root, 'solr', 'data', ::Rails.env)
    end
    
    def pid_dir
      @pid_dir ||= configuration_from_key('solr', 'pid_dir') || File.join(::Rails.root, 'solr', 'pids', ::Rails.env)
    end
    
    #
    # The solr home directory. Sunspot::Rails expects this directory
    # to contain a config, data and pids directory. See
    # Sunspot::Rails::Server.bootstrap for more information.
    #
    # ==== Returns
    #
    # String:: solr_home
    #
    def solr_home
      @solr_home ||= configuration_from_key('solr', 'solr_home')
      @solr_home ||= File.join(::Rails.root, 'solr')
    end
    
    #
    # Solr start jar
    #
    def solr_jar
      @solr_jar ||= configuration_from_key('solr', 'solr_jar')
    end
    
    #
    # Minimum java heap size for Solr instance
    #
    def min_memory
      @min_memory ||= configuration_from_key('solr', 'min_memory')
    end
    
    #
    # Maximum java heap size for Solr instance
    #
    def max_memory
      @max_memory ||= configuration_from_key('solr', 'max_memory')
    end
    
    #
    # Interface on which to run Solr
    #
    def bind_address
      @bind_address ||= configuration_from_key('solr', 'bind_address')
    end
    
    def read_timeout
      @read_timeout ||= configuration_from_key('solr', 'read_timeout')
    end
    
    def open_timeout
      @open_timeout ||= configuration_from_key('solr', 'open_timeout')
    end
    
    #
    # Whether or not to disable Solr.
    # Defaults to false.
    #
    def disabled?
      @disabled ||= (configuration_from_key('disabled') || false)
    end
    
    #
    # The callback to use when automatically indexing records.
    # Defaults to after_save.
    #
    def auto_index_callback
      @auto_index_callback ||= (configuration_from_key('auto_index_callback') || 'after_save')
    end
    
    #
    # The callback to use when automatically removing records after deletation.
    # Defaults to after_destroy.
    #
    def auto_remove_callback
      @auto_remove_callback ||= (configuration_from_key('auto_remove_callback') || 'after_destroy')
    end
    
    def url(u = nil)
      s = self.hostname
      if !s.start_with? 'http'
        res = "#{self.scheme}://"
        res << "#{u}@" if !u.blank?
        res << s
      else
        res = s.dup
      end
      res << "#{self.path}"
    end
    
    def write_url
      self.url(self.userinfo)
    end
    
    def uid_prefix
      unless defined?(@uid_prefix)
        @uid_prefix ||= configuration_from_key('solr', 'uid_prefix')
      end
      @uid_prefix
    end
    
    def uid_code
      unless defined?(@uid_code)
        @uid_code ||= configuration_from_key('solr', 'uid_code')
      end
      @uid_code
    end
    
    def configuration_from_key( *keys )
      value = user_configuration_from_key(*keys)
      value ||= default_configuration_from_key(*keys)
    end
    
    private
    
    #
    # Logging in rails_root/log as solr_<environment>.log as a
    # default.
    #
    # ===== Returns
    #
    # String:: default_log_file_location
    #
    def default_log_file_location
      File.join(::Rails.root, 'log', "solr_" + ::Rails.env + ".log")
    end
    
    def all_configurations
      @all_configurations ||=
        begin
          settings_file = Rails.root.join('config', 'flare.yml')
          settings_file.exist? ? YAML.load_file(settings_file) : {}
        end
    end
    
    #
    # return a specific key from the user configuration in config/sunspot.yml
    #
    # ==== Returns
    #
    # Mixed:: requested_key or nil
    #
    def user_configuration_from_key( *keys )
      keys.inject(user_configuration) do |hash, key|
        hash[key] if hash
      end
    end
    
    def default_configuration_from_key( *keys )
      keys.inject(default_configuration) do |hash, key|
        hash[key] if hash
      end
    end
    
    #
    # Memoized hash of configuration options for the current Rails environment
    # as specified in config/sunspot.yml
    #
    # ==== Returns
    #
    # Hash:: configuration options for current environment
    #
    def user_configuration
      @user_configuration ||= all_configurations[::Rails.env]
    end
    
    def default_configuration
      @default_configuration ||= all_configurations['default']
    end
     
  protected

    #
    # When a specific hostname, port and path aren't provided in the
    # sunspot.yml file, look for a key named 'url', then check the
    # environment, then fall back to a sensible localhost default.
    #
    
    def solr_url
      if ENV['SOLR_URL'] || ENV['WEBSOLR_URL']
        URI.parse(ENV['SOLR_URL'] || ENV['WEBSOLR_URL'])
      end
    end
    
    def default_hostname
      'localhost'
    end
    
    def default_scheme
      'http'
    end
    
    def default_userinfo
      nil
    end
    
    def default_path
      '/solr/default'
    end
  end
end