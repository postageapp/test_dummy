class TestDummy::Operation
  # == Extensions ===========================================================
  
  # == Constants ============================================================
  
  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================

  def initialize(options)
    flatten_to_key_if_any(operation, options, :only)
    flatten_to_key_if_any(operation, options, :except)

    merge_with_options!(operation, options)
    merge_inherit_options!(operation, options)

    # The :inherit directive is used to pass arguments through to the
    # create_dummy call on the association's class.
    if (inherit = options[:inherit])
      TestDummy::OptionsConverter.import_inherit_options(operation, :inherit, options[:inherit])
      operation[:inherit] = 

      Hash[
        inherit.collect do |attribute, spec|
          [
            attribute.to_sym,
            case (spec)
            when Array
              spec.collect(&:to_sym)
            when String
              spec.split('.').collect(&:to_sym)
            when Proc
              spec
            end
          ]
        end
      ]

      create_options_proc = lambda do |target, model, with_attributes|
        operation[:inherit].each do |attribute, spec|
          target[attribute] ||=
            case (spec)
            when Array
              spec.inject(model) do |_model, _method|
                _model ? _model.send(_method) : nil
              end
            when Proc
              proc.call(model, with_attributes)
            end
        end
      end
    end

    if (from = options[:from])
      if (block)
        raise TestDummy::Exception, "Cannot use block, :with, or :from option at the same time."
      end

      case (from)
      when Array
        # Already in correct form
      when Hash
        from = from.to_a
      when String
        from = from.split('.')
      else
        raise TestDummy::Exception, "Argument to :from must be a String, Array or Hash."
      end
    end
  end

  def blah
  end
end