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

  def define_operation(fields, options, &block)
    from = nil
    create_options_proc = nil

    @operations << TestDummy::Operation.new(options, &block)

    if (block_given?)
      operation[:block] = proc
    end

    if (fields.any?)
      if (operation[:block])
        operation[:fields] = fields
        @test_dummy << operation
      else
        remainder = fields.reject do |field|
          reflection_class, foreign_key = TestDummy::Support.reflection_properties(self, field)

          if (reflection_class and foreign_key)
            field_operation = operation.dup

            field_operation[:block] ||= lambda do |model, with_attributes|
              unless ((with_attributes and (with_attributes.key?(field) or with_attributes.key?(foreign_key))) or model.send(field).present?)
                object = from && from.inject(model) do |_model, _method|
                  _model ? _model.send(_method) : nil
                end

                reflection_class.create_dummy do |target|
                  if (create_options_proc)
                    create_options_proc.call(target, model, with_attributes)
                  end
                end
              end
            end
          end
        end
      end

      if (remainder.any?)
        @test_dummy << operation
      end
    else
      @test_dummy << operation
    end
  end

protected
end
