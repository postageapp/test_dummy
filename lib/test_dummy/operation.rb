class TestDummy::Operation
  # == Properties ===========================================================

  attr_reader :source_methods
  attr_reader :source_keys
  attr_reader :only
  attr_reader :except
  attr_reader :model_class
  attr_reader :foreign_key
  
  # == Instance Methods =====================================================

  def initialize(options)
    @blocks = [ ]

    assign_block_options!(options)
    assign_fields_options!(options)

    assign_only_options!(options)
    assign_except_options!(options)

    assign_with_options!(options)

    assign_from_options!(options)
    assign_reflection_options!(options)

    assign_inherit_options!(options)
  end

  def fields(tags = nil)
    if (trigger?(tags))
      @fields
    else
      [ ]
    end
  end

  def trigger?(tags)
    if (@only)
      return false if (!tags or (tags & @only).empty?)
    end

    if (@except)
      return false if (tags and (tags & @except).any?)
    end

    true
  end

  def assignments(model, create_options, tags)
    unless (trigger?(tags))
      return [ ]
    end

    @fields.reject do |field|
      field and (
        (create_options and @source_keys.find { |k| create_options.key?(k) }) or
        (model and @source_methods.find { |m| model.__send__(m) })
      )
    end
  end

  def apply!(model, create_options, tags)
    _assignments = assignments(model, create_options, tags)

    return if (_assignments.empty?)

    value = nil
    
    @blocks.find do |block|
      value =
        case (block.arity)
        when 0
          block.call
        when 1
          block.call(model)
        when 2
          block.call(model, _assignments)
        when 3
          block.call(model, _assignments, tags)
        else
          block.call(model, _assignments, tags, create_options)
        end

      !value.nil?
    end

    model and !value.nil? and _assignments.each do |field|
      next unless (field)
      
      model.__send__(:"#{field}=", value)
    end
  end

protected
  def flatten_any(options, key)
    array = options[key]

    return unless (array)

    array = [ array ].flatten.compact.collect(&:to_sym)

    return unless (array.any?)

    array
  end

  def assign_block_options!(options)
    return unless (options[:block])

    @blocks << options[:block]
  end

  def assign_fields_options!(options)
    @fields = options[:fields] || [ nil ]

    @source_keys = [ ]
    @source_methods = [ ]

    @fields and @fields.each do |field|
      next unless (field)

      @source_keys << field
      @source_keys << field.to_s

      @source_methods << field
    end
  end

  def assign_only_options!(options)
    @only = flatten_any(options, :only)
  end

  def assign_except_options!(options)
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
      lambda { respond_to?(with) ? send(with) : TestDummy::Helper.send(with) }
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

  def block_for_inherit_options(spec)
    case (spec)
    when Proc
      return spec
    when Array
      # Use as-is
    when String
      spec = spec.split('.').collect(&:to_sym)
    when Symbol
      spec = [ spec ]
    end

    lambda do |model|
      spec.inject(model) do |_model, _method|
        _model ? _model.send(_method) : nil
      end
    end
  end

  def assign_reflection_options!(options)
    return unless (options[:foreign_key])

    @model_class = options[:model_class]
    @foreign_key = options[:foreign_key]

    @source_keys << @foreign_key
    @source_keys << @foreign_key.to_s

    @source_keys.uniq!

    @source_methods << @foreign_key

    @source_methods.uniq!
  end

  def assign_inherit_options!(options)
    inherit = options[:inherit]

    return unless (inherit)

    case (inherit)
    when Hash
      # Use as-is
    when Symbol, String
      inherit = { inherit.to_sym => [ inherit.to_sym ] }
    else
      # Not supported, should raise.
    end

    @inheritance_procs =
      inherit.collect do |attribute, spec|
        [
          attribute.to_sym,
          block_for_inherit_options(spec)
        ]
      end

    @blocks << lambda do |model|
      @model_class.create_dummy(
        Hash[
          @inheritance_procs.collect do |attribute, proc|
            [ attribute, proc.call(model) ]
          end
        ]
      )
    end
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
