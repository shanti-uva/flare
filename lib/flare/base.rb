module Flare
  module Base
    extend ActiveSupport::Concern
    
    def uid
      self.class.uid(self.id)
    end
    
    def uid_query
      "uid:#{self.uid}"
    end
    
    def search
      klass = self.class      
      scope = klass.flare_scope
      scope.blank? ? klass.session.find(self.uid) : klass.session.find_by((scope+[self.uid_query]).join(' AND '))['docs'].first
    end
    
    def remove
      klass = self.class
      klass.session.delete_by((klass.flare_scope+[self.uid_query]).join(' AND '))
    end
    
    def remove!
      klass = self.class
      klass.session.delete_by!((klass.flare_scope+[self.uid_query]).join(' AND '))
    end
    
    def index
      klass = self.class
      begin
        self.remove
        klass.session.index(document_for_rsolr)
        return true
      rescue => e
        logger.error "Solr index could not be updated for feature #{self.uid}"
        logger.error e.to_s
        logger.error e.backtrace.join("\n")
        return false
      end
    end
    
    def index!
      klass = self.class
      begin
        self.remove
        klass.session.index!(document_for_rsolr)
        return true
      rescue => e
        logger.error "Solr index could not be updated for feature #{self.uid}"
        logger.error e.to_s
        logger.error e.backtrace.join("\n")
        return false
      end
    end
    
    def queued_index(priority: Flare::IndexerJob::MEDIUM)
      IndexerJob.set(priority: priority).perform_later(self)
    end
    
    module ClassMethods
      # Indexes objects on the singleton session.
      #
      # ==== Parameters
      #
      # objects...<Object>:: objects to index (may pass an array or varargs)
      #
      # ==== Example
      #
      #   post1, post2 = new Array(2) { Post.create }
      #   Sunspot.index(post1, post2)
      #
      # Note that indexed objects won't be reflected in search until a commit is
      # sent - see Sunspot.index! and Sunspot.commit
      #
      def index(*documents)
        session.index(*documents)
      end

      # Indexes objects on the singleton session and commits immediately.
      #
      # See: Sunspot.index and Sunspot.commit
      #
      # ==== Parameters
      #
      # objects...<Object>:: objects to index (may pass an array or varargs)
      #
      def index!(*objects)
        session.index!(*objects)
      end

      # Commits (soft or hard) the singleton session
      #
      # When documents are added to or removed from Solr, the changes are
      # initially stored in memory, and are not reflected in Solr's existing
      # searcher instance. When a hard commit message is sent, the changes are written
      # to disk, and a new searcher is spawned. Commits are thus fairly
      # expensive, so if your application needs to index several documents as part
      # of a single operation, it is advisable to index them all and then call
      # commit at the end of the operation.
      # Solr 4 introduced the concept of a soft commit which is much faster
      # since it only makes index changes visible while not writing changes to disk.
      # If Solr crashes or there is a loss of power, changes that occurred after
      # the last hard commit will be lost.
      #
      # Note that Solr can also be configured to automatically perform a commit
      # after either a specified interval after the last change, or after a
      # specified number of documents are added. See
      # http://wiki.apache.org/solr/SolrConfigXml
      #
      def commit(soft_commit = false)
        session.commit soft_commit
      end

      # Optimizes the index on the singletion session.
      #
      # Frequently adding and deleting documents to Solr, leaves the index in a
      # fragmented state. The optimize command merges all index segments into 
      # a single segment and removes any deleted documents, making it faster to 
      # search. Since optimize rebuilds the index from scratch, it takes some 
      # time and requires double the space on the hard disk while it's rebuilding.
      # Note that optimize also commits.
      def optimize
        session.optimize
      end
      
      def uid(id)
        self.uid_prefix.blank? ? id : "#{self.uid_prefix}-#{id}"
      end
      
      def uid_query(id)
        "uid:#{self.uid(id)}"
      end
      
      # 
      # Remove an object from the index using its class name and primary key.
      # Useful if you know this information and want to remove an object without
      # instantiating it from persistent storage
      #
      # ==== Parameters
      #
      # clazz<Class>:: Class of the object, or class name as a string or symbol
      # id::
      #   Primary key of the object. This should be the same id that would be
      #   returned by the class's instance adapter.
      #
      def remove(*ids)
        return if ids.blank?
        ids.flatten!
        scope = self.flare_scope
        if scope.blank?
          session.delete(ids.collect{ |id| self.uid(id) })
        else
          if ids.size==1
            session.delete_by((scope+[self.uid_query(ids.first)]).join(' AND '))
          else
            session.delete_by("(#{scope.join(' AND ')}) AND (#{ids.collect{|id| self.uid_query(id) }.join(' OR ')})")
          end
        end
      end

      # 
      # Remove an object by class name and primary key, and immediately commit.
      # See #delete and #commit
      #
      def remove!(*ids)
        remove(ids)
        session.commit
      end

      def remove_by(query)
        scope = self.flare_scope
        if scope.blank?
          session.delete_by(query)
        else
          if query.instance_of? Array
            session.delete_by(query.collect{|q| "(#{scope.join(' AND ')}) AND (#{q})"})
          else
            session.delete_by("(#{scope.join(' AND ')}) AND (#{query})")
          end
        end
      end
    
      def remove_by!(query)
        remove_by(query)
        session.commit
      end

      def flare_search(id)
        scope = flare_scope
        scope.blank? ? session.find(self.uid(id)) : session.find_by((scope+[self.uid_query(id)]).join(' AND '))['docs'].first
      end
          
      def search_by(query, options = {})
        scope = flare_scope
        scope.blank? ? session.find_by(query,options) : session.find_by("(#{scope.join(' AND ')}) AND (#{query})", options)
      end

      def paginate(options)
        paginate_options = options.dup
        scope = flare_scope
        paginate_options[:query] =  "(#{scope.join(' AND ')}) AND (#{paginate_options[:query]})" unless scope.blank?
        session.paginate(paginate_options)
      end

      #
      # True if documents have been added, updated, or removed since the last
      # commit.
      #
      # ==== Returns
      #
      # Boolean:: Whether there have been any updates since the last commit
      #
      def dirty?
        session.dirty?
      end

      # 
      # Sends a commit (soft or hard) if the session is dirty (see #dirty?).
      #
      def commit_if_dirty(soft_commit = false)
        session.commit_if_dirty soft_commit
      end
    
      #
      # True if documents have been removed since the last commit.
      #
      # ==== Returns
      #
      # Boolean:: Whether there have been any deletes since the last commit
      #
      def delete_dirty?
        session.delete_dirty?
      end

      # 
      # Sends a commit if the session has deletes since the last commit (see #delete_dirty?).
      #
      def commit_if_delete_dirty(soft_commit = false)
        session.commit_if_delete_dirty soft_commit
      end
    
      # Returns the configuration associated with the singleton session. See
      # Sunspot::Configuration for details.
      #
      # ==== Returns
      #
      # LightConfig::Configuration:: configuration for singleton session
      #
      def config
        session.config
      end

      # 
      # Resets the singleton session. This is useful for clearing out all
      # static data between tests, but probably nowhere else.
      #
      # ==== Parameters
      #
      # keep_config<Boolean>::
      #   Whether to retain the configuration used by the current singleton
      #   session. Default false.
      #
      def reset!(keep_config = false)
        config =
          if keep_config
            session.config
          else
            Configuration.build
          end
        @session = Session.new(config)
      end

      # 
      # Get the singleton session, creating it if none yet exists.
      #
      # ==== Returns
      #
      # Sunspot::Session:: the singleton session
      #
      def session #:nodoc:
        @session ||= Session.new
      end
      
      def uid_prefix
        @uid_prefix ||= nil
      end
      
      def uid_code
        @uid_code ||= nil
      end
      
      def flare_scope
        @scope ||= []
      end
    
      def setup(options)
        config = Flare::Configuration.new(options[:path])
        @session = Session.new(config)
        options_prefix = options[:uid_prefix]
        options_code = options[:uid_code]
        @uid_prefix = options_prefix.blank? ? config.uid_prefix : options_prefix
        @uid_code = options_code.blank? ? config.uid_code : options_code
        scope_hash = options[:scope]
        @scope = scope_hash.blank? ? [] : scope_hash.to_a.collect{|e| e.join(':')}
      end
    end
  end
end

