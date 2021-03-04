require 'flare/time_utils'

module Flare
  class IndexerJob < ApplicationJob
    include Flare::TimeUtils
    
    LOW = 6
    MEDIUM = 3
    HIGH = 0
    
    queue_as :default
    
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
      IndexerJob.delay_if_business_hours
      Rails.logger.fatal { "#{IndexerJob.now}: [INDEX] beginning indexing of #{object.id}." }
      object.index
      Rails.logger.fatal { "#{IndexerJob.now}: [INDEX] document indexed for #{object.id}." }
    end
  end
end
