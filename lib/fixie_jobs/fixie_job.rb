module Fixie
  class Job < ActiveRecord::Base
    set_table_name :fixie_jobs

    def execute!
      begin
        options = self.options.blank? ? [] : Fixie::Jobs.autoload_missing_constants { Marshal.load(Base64.decode64(self.options)) }
        if self.record_id
          self.klass.constantize.find(self.record_id).send(self.the_method, *options)
        else
          self.klass.constantize.send(self.the_method, *options)
        end
      rescue Exception => e
        LOGGER.error "#{ e.message }, #{ e.backtrace.first }"
      end
      destroy
    end
  end
end
