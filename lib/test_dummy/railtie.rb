case (Rails::VERSION::MAJOR)
when 2
  if (defined?(ActiveRecord) and defined?(ActiveRecord::Base))
    ActiveRecord::Base.send(:include, TestDummy)
  end
else
  class TestDummy::Railtie < Rails::Railtie
    railtie_name :test_dummy
  
    config.after_initialize do
      if (defined?(ActiveRecord) and defined?(ActiveRecord::Base))
        ActiveRecord::Base.send(:include, TestDummy)
      end
    end
  end
end
