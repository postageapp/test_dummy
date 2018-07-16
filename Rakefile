require 'rubygems'
require 'rake'

require 'bundler/setup'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name = "test_dummy"
    gem.summary = %q[Quick test data generator and fake model maker]
    gem.description = %q[Test Dummy allows you to define how to fake models automatically so that you can use dummy data for testing instead of fixtures. Dummy models are always generated using the current schema and don't need to me migrated like fixtures.]
    gem.email = "tadman@postageapp.com"
    gem.homepage = "http://github.com/postageapp/test_dummy"
    gem.authors = %w[ tadman ]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'

Rake::TestTask.new do |test|
  test.pattern = 'test/unit/test_*.rb'
end

task default: :test
