module Fixie
  def push(task, *args)
    ActiveRecord::Base.verify_active_connections! if defined?(ActiveRecord)

    type    = (self.kind_of? Class) ? self.to_s : self.class.to_s
    id      = (self.kind_of? Class) ? nil : self.id
    task    = task.to_s
    options = args.empty? ? nil : Base64.encode64(Marshal.dump(args))

    job = Job.create! :klass => type, :record_id => id, :the_method => task, :options => options

    LOGGER.info "[#{Time.now.to_s(:db)}] Pushed #{task} on #{type} #{id}"
    job
  rescue Exception => error
    LOGGER.error "[#{Time.now.to_s(:db)}] ERROR #{error.message}"
    raise 
  end
end

module Fixie
  class ActiveRecord::Base
    include Fixie
  end
end

class Class
  include Fixie
end

ActiveRecord::Base.send(:include, Fixie)
