case (Rails::VERSION::MAJOR)
when 2
  if (defined?(ActiveRecord) and defined?(ActiveRecord::Base))
    ActiveRecord::Base.send(:include, TestDummy)
  end
  if (defined?(ActiveSupport) and defined?(ActiveSupport::TestCase))
    ActiveSupport::TestCase.send(:include, TestDummy::TestHelper)
  end
else
  class TestDummy::Railtie < Rails::Railtie
    def self.apply!
      if (defined?(ActiveRecord))
        ActiveRecord::Base.send(:include, TestDummy)
      end

      ActiveSupport::TestCase.send(:include, TestDummy::TestHelper)
    end
    
    config.before_configuration do
      apply!
    end
  end
end
