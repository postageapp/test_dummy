require_relative '../test_dummy'

case (Rails::VERSION::MAJOR)
when 2
  if (defined?(ActiveRecord) and defined?(ActiveRecord::Base))
    ActiveRecord::Base.send(:include, TestDummy)
  end
  if (defined?(ActiveSupport) and defined?(ActiveSupport::TestCase))
    ActiveSupport::TestCase.send(:include, TestDummy::TestHelper)
  end
  if (defined?(Test) and defined?(Test::Unit))
    Test::Unit::TestCase.send(:include, TestDummy::TestHelper)
  end
else
  class TestDummy::Railtie < Rails::Railtie
    def self.apply!
      if (defined?(ActiveRecord) and defined?(ActiveRecord::Base))
        ActiveRecord::Base.send(:include, TestDummy)
      end

      if (defined?(ActiveSupport) and defined?(ActiveSupport::TestCase))
        ActiveSupport::TestCase.send(:include, TestDummy::TestHelper)
      end

      if (defined?(Test) and defined?(Test::Unit))
        Test::Unit::TestCase.send(:include, TestDummy::TestHelper)
      end

      if (defined?(MiniTest) and defined?(MiniTest::Unit))
        MiniTest::Unit::TestCase.send(:include, TestDummy::TestHelper)
      end
    end
    
    config.to_prepare do
      self.apply!
    end
  end
end
