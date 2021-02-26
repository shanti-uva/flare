module Flare
  class IndexerJob < ApplicationJob
    LOW = 6
    MEDIUM = 3
    HIGH = 0
    
    queue_as :default
    @@count = 0
    around_enqueue do |job, block|
      object = job.arguments.first
      previous = Delayed::Job.where(reference: object).first
      if previous.nil?
        block.call
        delayed_job = Delayed::Job.find(job.provider_job_id)
        delayed_job.update!(reference: object)
      else
        priority = job.priority || 0
        previous.update!(priority: priority) if priority < previous.priority
      end
    end
    
    def perform(object)
      Rails.logger.fatal { "#{Time.now}: [INDEX] beginning indexing of #{object.id}." }
      object.index
      Rails.logger.fatal { "#{Time.now}: [INDEX] document indexed for #{object.id}." }
    end
    
    after_perform do |job|
      if @@count == 100
        Flare.commit
        Rails.logger.fatal { "#{Time.now}: [INDEX] commiting index." }
        @@count = 0
      else
        @@count += 1
      end
    end
  end
end
