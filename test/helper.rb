require 'bundler/setup'

gem 'test-unit'

require 'test/unit'

ENV['RAILS_ENV'] = 'test'

base_path = File.dirname(__FILE__)

$LOAD_PATH.unshift(base_path)
$LOAD_PATH.unshift(File.join(base_path, '..', 'lib'))
$LOAD_PATH.unshift(File.join(base_path, '..', 'test', 'models'))

require 'rails'
require 'active_record'

require 'test_dummy'

require 'ostruct'

TestDummy::Railtie.apply!

class Test::Unit::TestCase
  include TestDummy::TestHelper

  def assert_created(model)
    assert model, "Model should not be nil"

    assert_equal [ ], model.errors.full_messages
    assert_equal true, model.valid?, "Model is not valid."

    assert_equal false, model.new_record?, "Model has not been saved."
  end
end

class TestDummy::Application < Rails::Application
  config.active_support.test_order = :random
  config.active_support.deprecation = :warn
end

TestDummy.dummy_extensions_path = File.expand_path('dummy', File.dirname(__FILE__))

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: File.expand_path('db/test.sqlite3', base_path)
)

if (defined?(ActiveRecord::MigrationContext))
  ActiveRecord::MigrationContext.new(File.expand_path('db/migrate', base_path)).migrate
elsif (ActiveRecord::Migrator.respond_to?(:migrate))
  ActiveRecord::Migrator.migrate(File.expand_path('db/migrate', base_path))
else
  raise 'Cannot run migrations, no migrator found.'
end

ActiveSupport::Dependencies.autoload_paths << File.expand_path('models', base_path)

# Trigger loading the Rails root path here
Rails.root

# Example definitions that are added as extensions to the TestDummy::Helper
# module for use by default.

TestDummy.define do
  dummy :description,
    with: :phonetic_string

  dummy :phonetic_string do
    TestDummy::Helper.random_phonetic_string(32)
  end
end

# For avoiding protected_attributes testing, stub out the function

class ActiveRecord::Base
  def self.attr_accessible(*args)
  end
end
