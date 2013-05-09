module TestDummy::TestHelper
  def dummy(scope, *tags)
    create_attributes =
      case (tags.last)
      when Hash
        tags.pop
      else
        { }
      end

    instance = scope.respond_to?(:build) ? scope.build(create_attributes) : scope.new(create_attributes)

    if (block_given?)
      yield(instance)
    end

    instance.dummy!(create_attributes, tags)
    
    instance.save!
    instance
  end
  alias_method :a, :dummy
  alias_method :an, :dummy
  alias_method :one_of, :dummy
end
