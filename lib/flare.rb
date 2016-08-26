require 'set'
require 'time'
require 'date'
require 'enumerator'
require 'cgi'
begin
  require 'rsolr'
rescue LoadError
  require 'rubygems'
  require 'rsolr'
end

%w(configuration indexer session).each do |filename|
  require File.join(File.dirname(__FILE__), 'flare', filename)
end

#
# The Flare module provides class-method entry points to most of the
# functionality provided by the Flare library. Internally, the Flare
# singleton class contains a (non-thread-safe!) instance of Flare::Session,
# to which it delegates most of the class methods it exposes. In the method
# documentation below, this instance is referred to as the "singleton session".
#
# Though the singleton session provides a convenient entry point to Flare,
# it is by no means required to use the Flare class methods. Multiple sessions
# may be instantiated and used (if you need to connect to multiple Solr
# instances, for example.)
#
# Note that the configuration of classes for index/search (the +setup+
# method) is _not_ session-specific, but rather global.
#
module Flare
  class <<self
    # 
    # Clients can inject a session proxy, allowing them to implement custom
    # session-management logic while retaining the Sunspot singleton API as
    # an available interface. The object assigned to this attribute must
    # respond to all of the public methods of the Sunspot::Session class.
    #
    attr_writer :session

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
    def remove_by_id(*ids)
      session.remove_by_id(ids)
    end

    # 
    # Remove an object by class name and primary key, and immediately commit.
    # See #remove_by_id and #commit
    #
    def remove_by_id!(*ids)
      session.remove_by_id!(ids)
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
  end
end
