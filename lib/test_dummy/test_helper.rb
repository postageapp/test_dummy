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

    instance.class.dummy_definition.apply!(instance, create_attributes, tags)

    instance.save!

    instance.class.dummy_definition.apply_after_save!(instance, create_attributes, tags)

    instance
  end
  alias_method :a, :dummy
  alias_method :an, :dummy
  alias_method :one_of, :dummy
end
