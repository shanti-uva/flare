require 'base64'

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
    # Sunspot::Configuration object for this session
    #
    attr_reader :config

    # 
    # Sessions are initialized with a Sunspot configuration and a Solr
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
    # See Sunspot.index
    #
    def index(*documents)
      documents.flatten!
      @adds += documents.length
      indexer.add_documents(documents)
    end

    # 
    # See Sunspot.index!
    #
    def index!(*objects)
      index(*objects)
      commit
    end

    #
    # See Sunspot.commit
    #
    def commit(soft_commit = false)
      @adds = @deletes = 0
      connection.commit :commit_attributes => {:softCommit => soft_commit}
    end

    #
    # See Sunspot.optimize
    #
    def optimize
      @adds = @deletes = 0
      connection.optimize
    end

    # 
    # See Sunspot.remove_by_id
    #
    def remove_by_id(*ids)
      indexer.remove_by_id(ids)
    end

    # 
    # See Sunspot.remove_by_id!
    #
    def remove_by_id!(*ids)
      remove_by_id(ids)
      commit
    end

    # 
    # See Sunspot.dirty?
    #
    def dirty?
      (@deletes + @adds) > 0
    end

    # 
    # See Sunspot.commit_if_dirty
    #
    def commit_if_dirty(soft_commit = false)
      commit soft_commit if dirty?
    end
    
    # 
    # See Sunspot.delete_dirty?
    #
    def delete_dirty?
      @deletes > 0
    end

    # 
    # See Sunspot.commit_if_delete_dirty
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
      @connection ||= self.class.connection_class.connect(url: config.url, read_timeout: config.read_timeout, open_timeout: config.open_timeout)
    end

    def indexer
      @indexer ||= Indexer.new(connection)
    end
  end
end