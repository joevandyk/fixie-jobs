namespace :fixie do
  namespace :jobs do
    desc "Start processing jobs (process is daemonized)"
    task :start => :environment do
      begin
        Fixie::Jobs.feedback "Started processing jobs"
        Fixie::Jobs.process 
      rescue Exception => error
        Fixie::Jobs.feedback  error.message 
      end
    end
  end
end
