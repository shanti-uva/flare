module Flare
  module ActiveExtension
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_indexable(**options, &block)
        class_eval do
          include Flare::Base
        end
        setup(**options, &block)
      end
    end
  end
end