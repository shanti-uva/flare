module Flare
  module DelayedJob
    def DelayedJob.includes?(object, method)
      name = "#{object.class.name}##{method}"
      !Delayed::Job.all.collect(&:payload_object).select{ |o| o.display_name == name && o.object.id == object.id }.empty?
    end
  end
end