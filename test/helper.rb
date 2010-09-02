require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

gem 'rails'
require 'rails'
gem 'activerecord'

require 'test_dummy'

class Test::Unit::TestCase
end
