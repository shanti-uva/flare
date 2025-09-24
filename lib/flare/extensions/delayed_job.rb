module Flare
  module DelayedJobExtension
    extend ActiveSupport::Concern

    included do
      belongs_to :reference, polymorphic: true
    end

    class_methods do
    end
  end
end