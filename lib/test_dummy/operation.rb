class TestDummy::Operation
  # == Properties ===========================================================

  attr_reader :block
  attr_reader :fields
  attr_reader :only
  attr_reader :except
  attr_reader :with
  attr_reader :from
  attr_reader :inherit
  
  # == Instance Methods =====================================================

  def initialize(options)
    @blocks = [ ]

    assign_block_options!(options)

    assign_fields_options!(options)

    assign_only_options!(options)
    assign_except_options!(options)

    assign_with_options!(options)

    assign_from_options!(options)
    assign_inherit_options!(options)

    assign_reflection_options!(options)
  end

  def apply!(model, with_options, tags)
    if (@only)
      return if (!tags or (tags & @only).empty?)
    end

    if (@except)
      return if (tags and (tags & @except).any?)
    end

    if (@fields)
      @fields.each do |field|
        value = nil #...

        @blocks.each do |block|
          value = block.call(model, field, tags, with_options)

          break if (value)
        end
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

  def assign_fields_options!(options)
    @fields = options[:fields]
  end

  def assign_only_options!(options)
    @only = flatten_any(options, :only)
  end

  def assign_except_options!
    @except = flatten_any(options, :except)
  end

  def assign_with_options!(options)
    if (with = options[:with])
      @blocks << block_for_with_option(with)
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

  def assign_from_options!(options)
    if (from = options[:from])
      case (from)
      when Proc
        @from = from

        return
      when Array
        # Array is an acceptable format, left as-is
      when Hash
        from = from.to_a
      when String
        from = from.split('.')
      else
        raise TestDummy::Exception, "Argument to :from must be a String, Array or Hash."
      end

      @from = lambda do |model|
        from.inject(model) do |_model, _method|
          _model ? _model.send(_method) : nil
        end
      end
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

    @blocks << lambda do |target, model, with_attributes|
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

  def assign_reflection_options!(options)
    return unless (options[:class_name] and options[:foreign_key])

    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]

    @block ||= lambda do |model, with_attributes|
      unless ((with_attributes and (with_attributes.key?(field) or with_attributes.key?(foreign_key))) or model.send(field).present?)
        @from and @from.call(model)
      end
    end
  end


  def assign_block_options!(options)
    @blocks << options[:block]
  end

  # def ____________
  #   field_operation[:block] ||= lambda do |model, with_attributes|
  #     unless ((with_attributes and (with_attributes.key?(field) or with_attributes.key?(foreign_key))) or model.send(field).present?)
  #       object = from && from.inject(model) do |_model, _method|
  #         _model ? _model.send(_method) : nil
  #       end
  #     end
# 
  #     reflection_class.create_dummy do |target|
  #       if (create_options_proc)
  #         create_options_proc.call(target, model, with_attributes)
  #       end
  #     end
  #   end
  # end
end
