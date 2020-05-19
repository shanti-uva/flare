module Flare
  class IndexerJob < ApplicationJob
    LOW = 6
    MEDIUM = 3
    HIGH = 0
    
    queue_as :default
        
    around_enqueue do |job, block|
      object = job.arguments.first
      klass_name = object.class.name
      id = object.id
      priority = job.priority || 0
      previous = Delayed::Job.where(reference_id: id, reference_type: klass_name).first
      if previous.nil?
        block.call
        delayed_job = Delayed::Job.find(job.provider_job_id)
        delayed_job.update!(reference_id: id, reference_type: klass_name)
      else
        previous.update!(priority: priority) if priority < previous.priority
      end
    end
    
    def perform(object)
      object.index!
    end
  end
end
