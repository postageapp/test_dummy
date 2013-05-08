class TestDummy::Definition
  # == Extensions ===========================================================
  
  # == Constants ============================================================
  
  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================

  def initialize(operations = nil)
    @operations = operations ? operations.dup : [ ]
  end

  def clone
    self.class.new(@operations)
  end
  alias_method :dup, :clone

  def can_dummy_fields
    @operations.each_with_object([ ]) do |operation, collection|
      collection += operation.fields
    end.compact.uniq
  end

  def can_dummy?(*fields)
    return false unless (@test_dummy)

    fields = Hash[
      fields.flatten.compact.collect do |field|
        [ field.to_sym, false ]
      end
    ]
    
    @operations.each do |operation|
      operation_fields = operation[:fields]

      next unless (operation_fields)

      operation_fields.each do |field|
        fields[field] = true
      end
    end

    !fields.find do |field, found|
      !found
    end
  end

  def define_operation(model_class, fields, options)
    if (fields.any?)
      fields.each do |field|
        field_options = options.merge(
          :fields => [ field ]
        )

        class_name, foreign_key = TestDummy::Support.reflection_properties(model_class, field)

        if (class_name and foreign_key)
          field_options[:class_name] ||= class_name
          field_options[:foreign_key] ||= foreign_key
        end

        options.merge(
          :fields => [ field ]
        )

        @operations << TestDummy::Operation.new(field_options)
      end
    else
      @operations << TestDummy::Operation.new(options)
    end
  end

  def <<(operation)
    @operations << operation
  end

  def apply!(model, with_options, tags)
    @operations.each do |operation|
      operation.apply!(model, with_options, tags)
    end
  end
end
