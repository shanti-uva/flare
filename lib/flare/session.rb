require 'base64'
require 'faraday'

module Flare
  # 
  # A Flare session encapsulates a connection to Solr and a set of
  # configuration choices. Though users of Flare may manually instantiate
  # Session objects, in the general case it's easier to use the singleton
  # stored in the Flare module. Since the Flare module provides all of
  # the instance methods of Session as class methods, they are not documented
  # again here.
  #
  class Session
    class <<self
      attr_writer :connection_class #:nodoc:
      
      # 
      # For testing purposes
      #
      def connection_class #:nodoc:
        @connection_class ||= RSolr
      end
    end

    # 
    # Flare::Configuration object for this session
    #
    attr_reader :config

    # 
    # Sessions are initialized with a Flare configuration and a Solr
    # connection. Usually you will want to stick with the default arguments
    # when instantiating your own sessions.
    #
    def initialize(config = Flare::Configuration.new, connection = nil)
      @config = config
      yield(@config) if block_given?
      @connection = connection
      @deletes = @adds = 0
    end

    #
    # See Flare.index
    #
    def index(*documents)
      @adds += documents.length
      indexer.add_documents(documents)
    end

    # 
    # See Flare.index!
    #
    def index!(*objects)
      index(*objects)
      commit
    end

    #
    # See Flare.commit
    #
    def commit(soft_commit = false)
      @adds = @deletes = 0
      write_connection.commit :commit_attributes => {:softCommit => soft_commit}
    end

    #
    # See Flare.optimize
    #
    def optimize
      @adds = @deletes = 0
      write_connection.optimize
    end

    # 
    # See Flare.remove_by
    #
    def delete(*ids)
      indexer.delete(ids)
    end

    # 
    # See Flare.remove_by!
    #
    def delete!(*ids)
      delete(ids)
      commit
    end

    def delete_by(query)
      indexer.delete_by(query)
    end
    
    def delete_by!(query)
      delete_by(query)
      commit
    end
    
    def find(id)
      indexer.find(id)
    end
    
    def find_by(query, options = {}, full_response = false)
      indexer.find_by(query, options, full_response)
    end

    def paginate(options)
      indexer.paginate(options)
    end

    # 
    # See Flare.dirty?
    #
    def dirty?
      (@deletes + @adds) > 0
    end

    # 
    # See Flare.commit_if_dirty
    #
    def commit_if_dirty(soft_commit = false)
      commit soft_commit if dirty?
    end
    
    # 
    # See Flare.delete_dirty?
    #
    def delete_dirty?
      @deletes > 0
    end

    # 
    # See Flare.commit_if_delete_dirty
    #
    def commit_if_delete_dirty(soft_commit = false)
      commit soft_commit if delete_dirty?
    end
    
    private

    # 
    # Retrieve the Solr connection for this session, creating one if it does not
    # already exist.
    #
    # ==== Returns
    #
    # RSolr::Connection::Base:: The connection for this session
    #
    def connection
      if @connection.nil?
        options = {url: config.url, timeout: config.read_timeout, open_timeout: config.open_timeout}
        options[:ssl] = {verify_mode: config.verify_mode} unless config.verify_mode.nil?
        faraday_connection = Faraday.new(options)
        @connection = self.class.connection_class.connect(faraday_connection, url: config.url)
      end
      @connection
    end
    
    def write_connection
      if @write_connection.nil?
        options = {url: config.write_url, timeout: config.read_timeout, open_timeout: config.open_timeout}
        options[:ssl] = {verify_mode: config.verify_mode} unless config.verify_mode.nil?
        faraday_connection = Faraday.new(options)
        @write_connection = self.class.connection_class.connect(faraday_connection, url: config.write_url)
      end
      @write_connection
    end
    
    def indexer
      @indexer ||= Indexer.new(connection, write_connection)
    end
  end
end
