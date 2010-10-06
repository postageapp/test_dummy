require 'rubygems'
require 'test/unit'

ENV['RAILS_ENV'] = 'test'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

gem 'rails'
require 'rails'
require 'active_record'

require 'test_dummy'

TestDummy::Railtie.apply!

class Test::Unit::TestCase
end

module TestDummy
  class Application < Rails::Application
    config.active_support.deprecation = :warn
  end
end

TestDummy::Application.initialize!
ActiveRecord::Base.establish_connection(Rails.env)
