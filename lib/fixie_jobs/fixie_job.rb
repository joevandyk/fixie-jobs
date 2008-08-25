module Fixie
  class Job < ActiveRecord::Base
    set_table_name :fixie_jobs

    def self.do_next_job!
      return unless job = find_next_job
      job.execute!
      job.mark_job_finished!
      job
    end

    def mark_job_started!
      timestamp :started_at
    end

    def mark_job_finished!
      timestamp :finished_at
    end

    # If record_id exists, find the AR object and send it the method.  Otherwise, send the method to the class.
    def execute!
      options = self.options.blank? ? [] : Fixie::Jobs.decode(self.options) 
      if self.record_id
        self.klass.constantize.find(self.record_id).send(self.the_method, *options)
      else
        self.klass.constantize.send(self.the_method, *options)
      end
    end

    # Finds the next job to run.  
    def self.find_next_job
      transaction do
        job = find :first, :conditions => 'started_at is null', :order => 'priority desc, created_at asc', :lock => true 
        return nil unless job
        return find_next_job if job.started_at  # If job has been started by another process, try again.
        job.mark_job_started!
        return job
      end
    end

    # Given a column (probably finished_at or started_at), update its value to be now().
    def timestamp column
      connection.execute "update fixie_jobs set #{column} = now() where id = #{self.id}"
    end

  end
end
