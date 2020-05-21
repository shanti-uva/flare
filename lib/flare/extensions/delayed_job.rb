module Flare
  module DelayedJobExtension
    extend ActiveSupport::Concern

    included do
      belongs_to :reference, polymorphic: true
    end

    module ClassMethods
    end
  end
end