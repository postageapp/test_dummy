module TestDummy::TestHelper
  def dummy(scope, options = { })
    instance = scope.respond_to?(:build) ? scope.build(options) : scope.new(options)

    if (block_given?)
      yield(instance)
    end
    
    instance.dummy!
    
    instance.save!
    instance
  end
  alias_method :a, :dummy
  alias_method :an, :dummy
  alias_method :one_of, :dummy
end
