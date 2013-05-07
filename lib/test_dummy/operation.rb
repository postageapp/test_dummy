class TestDummy::Operation
  # == Extensions ===========================================================
  
  # == Constants ============================================================
  
  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================

  def initialize(options)
    assign_only_options!(options)
    assign_except_options!(options)

    assign_with_options!(options)
    assign_inherit_options!(options)

    # The :inherit directive is used to pass arguments through to the
    # create_dummy call on the association's class.

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

protected
  def flatten_any(options, key)
    array = options[key]

    return unless (array)

    array = array.flatten.compact.collect(&:to_sym)

    return unless (array.any?)

    array
  end

  def assign_only_options!(options)
    @only = flatten_any(options, :only)
  end

  def assign_except_options!
    @except = flatten_any(options, :except)
  end

  def assign_with_options!(options)
    if (with = options[:with])
      if (@block)
        raise TestDummy::Exception, "Cannot use block and :with option at the same time."
      end

      @block = block_for_with_option(with)
    end
  end

  def block_for_with_option(with)
    case (with)
    when Proc
      with
    when String, Symbol
      lambda { send(with) }
    else
      lambda { with }
    end
  end

  def assign_inherit_options!(options)
    inherit = options[:inherit]

    return unless (inherit)

    @inherit = Hash[
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

    @create_options_proc = lambda do |target, model, with_attributes|
      @inherit.each do |attribute, spec|
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
end
