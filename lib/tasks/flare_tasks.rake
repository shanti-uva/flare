namespace :flare do
  namespace :jobs do
    desc "Running a delayed_job worker"
    task :work => :environment do
      Rails.application.configure do
        config.cache_classes = true
      end
      worker = Delayed::Worker.new({quiet: false})
      worker.start
    end
  end
end