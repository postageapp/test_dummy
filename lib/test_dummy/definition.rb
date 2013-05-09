class TestDummy::Definition
  # == Extensions ===========================================================
  
  # == Properties ===========================================================

  attr_reader :operations
  
  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================

  def initialize(operations = nil)
    @operations = operations ? operations.dup : [ ]
  end

  # Applies the operations defined in this definition to the model supplied,
  # taking into account any options used for creation and only triggering based
  # on the tags specified.
  def apply!(model, create_options, tags)
    @operations.each do |operation|
      operation.apply!(model, create_options, tags)
    end

    true
  end

  # Creates a copy of this Definition.
  def clone
    self.class.new(@operations)
  end
  alias_method :dup, :clone

  # Returns a list of fields that could be populated with dummy data when the
  # given tags are employed.
  def fields(*tags)
    tags = tags.flatten.compact

    @operations.each_with_object([ ]) do |operation, collection|
      collection.concat(operation.fields(tags))
    end.compact.uniq
  end

  def fields?(*matching_fields)
    matching_fields = Hash[
      matching_fields.flatten.compact.collect do |field|
        [ field.to_sym, false ]
      end
    ]
    
    @operations.each do |operation|
      operation_fields = operation.fields

      next unless (operation_fields)

      operation_fields.each do |field|
        next unless (field)

        matching_fields[field] = true
      end
    end

    !matching_fields.find do |field, found|
      !found
    end
  end

  def define_operation(model_class, fields, options)
    if (fields.any?)
      fields.each do |field|
        field_options = options.merge(
          :fields => [ field ].flatten.collect(&:to_sym)
        )

        model_class, foreign_key = TestDummy::Support.reflection_properties(model_class, field)

        if (model_class and foreign_key)
          field_options[:model_class] ||= model_class
          field_options[:foreign_key] ||= foreign_key
        end

        @operations << TestDummy::Operation.new(field_options)
      end
    else
      @operations << TestDummy::Operation.new(options)
    end
  end

  def <<(operation)
    @operations << operation
  end
end
