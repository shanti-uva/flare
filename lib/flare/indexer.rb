module Flare
  # 
  # This class presents a service for adding, updating, and removing data
  # from the Solr index. An Indexer instance is associated with a particular
  # setup, and thus is capable of indexing instances of a certain class (and its
  # subclasses).
  #
  class Indexer #:nodoc:

    def initialize(connection)
      @connection = connection
    end

    # 
    # Remove the model from the Solr index by specifying the class and ID
    #
    def delete(*ids)
      ids.flatten!
      @connection.delete_by_id(ids)
    end
    
    def add_documents(documents)
      @connection.add(documents)
    end
    
    def delete_by(query)
      @connection.delete_by_query(query)
    end
    
    def find_by(query)
      resp = @connection.get('select', params: {q: query})
      resp['response']
    end
    
    def find(id)
      find_by("uid:#{id}")['docs'].first
    end
  end
end