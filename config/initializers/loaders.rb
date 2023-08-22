ActiveSupport.on_load(:active_record) do
  require 'flare/extensions/active_extension'
  include Flare::ActiveExtension
end
ActiveSupport.on_load(:active_resource) do
  require 'flare/extensions/active_extension'
  include Flare::ActiveExtension
end