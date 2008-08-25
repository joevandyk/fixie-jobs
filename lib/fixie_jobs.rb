module Fixie
  LOGGER = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}_fixie_jobs.log")
  class Jobs
    trap('TERM') { puts 'Exiting...'; $exit = true }
    trap('INT')  { puts 'Exiting...'; $exit = true }

    def self.process(daemonize = true)
      pid = fork do
        Signal.trap('HUP', 'IGNORE') # Don't die upon logout
        loop { pop }
      end

      if daemonize
        File.open("#{RAILS_ROOT}/tmp/pids/fixie_jobs_#{RAILS_ENV}.pid", "w") do |pid_file|
          pid_file.puts pid
        end
        Process.detach(pid)
      end
    end

    # Given a string, convert it back into Ruby objects.
    def self.decode string
      autoload_missing_constants { Marshal.load(Base64.decode64(string)) }
    end

    # Given an object, encode it into plain text.
    def self.encode object
      Base64.encode64(Marshal.dump(object))
    end

    # thanks err: http://errtheblog.com/posts/48-aliasmethodbling.  Helps when unmarshalling ruby objects from text.
    def self.autoload_missing_constants
      yield
    rescue ArgumentError => error
      lazy_load ||= Hash.new { |hash, key| hash[key] = true; false }
      retry if error.to_s.include?('undefined class') && 
        !lazy_load[error.to_s.split.last.constantize]
      raise error
    end

    def self.pop
      exit if $exit == true
      begin
        if job = Fixie::Job.do_next_job!
          LOGGER.info "[#{Time.now.to_s(:db)}] Popped #{job.the_method} on #{job.klass} #{job.record_id}"
          return pop
        end
      rescue Exception => error
        LOGGER.error "[#{Time.now.to_s(:db)}] ERROR #{error.message}, #{ error.backtrace.first}"
      end
      sleep 0.25
    end

    def self.feedback(message)
      puts "=> [FIXIE JOB RUNNER] #{message}"
    end
  end

end
