require 'flare/time_utils'

module Flare
  class IndexerJob < ApplicationJob
    include Flare::TimeUtils
    
    LOW = 6
    MEDIUM = 3
    HIGH = 0
    
    queue_as :indexer
    
    around_enqueue do |job, block|
      object = job.arguments.first
      previous = Delayed::Job.where(queue: IndexerJob.queue_name, reference: object).first
      if previous.nil?
        block.call if !block.nil?
        delayed_job = Delayed::Job.find(job.provider_job_id)
        delayed_job.update!(reference: object)
      else
        priority = job.priority || 0
        previous.update!(priority: priority) if priority < previous.priority
      end
    end
    
    def perform(object)
      delay = Feature.config.delay_if_business_hours
      IndexerJob.delay_if_business_hours(delay) unless delay.nil?
      #Rails.logger.fatal { "#{IndexerJob.now}: [INDEX] beginning indexing of #{object.id}." }
      if object.class.post_to_index?
        object.index
      else
        object.fs_index
      end
      #Rails.logger.fatal { "#{IndexerJob.now}: [INDEX] document indexed for #{object.id}." }
    end
  end
end