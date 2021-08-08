module Flare
  module TimeUtils
    extend ActiveSupport::Concern
    
    START_HOUR = 8
    END_HOUR = 17
    GMT_OFFSET = -5
    DELAY = 15
    
    def wait_if_business_hours(daylight)
      return if daylight.blank?
      now = self.class.now
      end_time = self.class.end_time
      if !(now.saturday? || now.sunday?) && self.class.start_time<now && now<end_time
        delay = end_time - now
        #self.log.debug { "#{Time.now}: Resting until #{end_time}..." }
        sleep(delay)
      end
    end

    module ClassMethods
      def now
        Time.now + GMT_OFFSET.hours
      end

      def start_time
        now = self.now
        Time.new(now.year, now.month, now.day, START_HOUR)
      end

      def end_time
        now = self.now
        Time.new(now.year, now.month, now.day, END_HOUR)
      end
      
      def business_hours?
        now = self.now
        !(now.saturday? || now.sunday?) && self.start_time<now && now<self.end_time
      end
      
      def delay_if_business_hours
        if self.business_hours? && defined?(@@last)
          time_passed = self.now - @@last
          wait_time = DELAY - time_passed
          sleep(wait_time) if wait_time > 0
        end
        @@last = self.now
      end
    end
  end
end