require "flare/engine"
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
require 'active_resource'
require 'delayed_job_active_record'


require 'flare/base'
require 'flare/extensions/delayed_job'
Delayed::Job.send :include, Flare::DelayedJobExtension

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
  include Flare::Base
end
