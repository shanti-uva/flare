ActiveSupport.on_load(:active_record) do
  require_dependency 'flare/extensions/active_extension'
  include Flare::ActiveExtension
end
ActiveSupport.on_load(:active_resource) do
  require_dependency 'flare/extensions/active_extension'
  include Flare::ActiveExtension
end