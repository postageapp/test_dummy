class TestDummy::Operation
  # == Constants ============================================================

  VALID_OPTIONS = [
    :block,
    :fields,
    :only,
    :except,
    :after,
    :force,
    :with,
    :from,
    :model_class,
    :foreign_key,
    :inherit
  ].freeze

  # == Properties ===========================================================

  attr_reader :source_methods
  attr_reader :source_keys
  attr_reader :only
  attr_reader :except
  attr_reader :after
  attr_reader :model_class
  attr_reader :foreign_key
  
  # == Instance Methods =====================================================

  def initialize(options)
    @blocks = [ ]

    invalid_options = options.keys - VALID_OPTIONS

    if (invalid_options.any?)
      raise TestDummy::Exception, "Unknown options to #{self.class}: #{invalid_options.inspect}"
    end

    assign_block_options!(options)
    assign_fields_options!(options)

    assign_only_options!(options)
    assign_except_options!(options)
    assign_after_options!(options)

    assign_force_options!(options)

    assign_with_options!(options)

    assign_from_options!(options)
    assign_reflection_options!(options)
    assign_inherit_options!(options)
    assign_reflection_block!(options)

    assign_default_block!(options)
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
      return false
    end

    if (@force)
      return @fields
    end

    # ActiveRecord::Base derived models will return an array of strings listing
    # the fields that have been altered before the model is saved. This
    # includes any fields that have been populated through the constructor
    # call, carried through via scope, or have been altered through accessors.
    if (model and model.respond_to?(:changed))
      # If any of the source methods are listed as "changed", then this is
      # interpreted as a hit, that the fields are already defined or will be.
      if ((@source_methods & model.changed.collect(&:to_sym)).any?)
        return false
      end
    end

    # If this operation does not populate any fields, then there's no further
    # testing required. The processing can continue without assignments.
    unless (@fields)
      return
    end

    fields_not_assigned = @fields

    if (fields_not_assigned.any? and create_options)
      # If any of the source keys are listed in the options, then this is
      # interpreted as a hit, that the fields are already defined or will be.
      if ((@source_keys & create_options.keys.collect(&:to_sym)).any?)
        return false
      end
    end

    # If there are potentially unassigned fields, the only way to proceed is
    # to narrow it down to the ones that are still `nil`.
    if (model and fields_not_assigned and fields_not_assigned.any?)
      fields_not_assigned = fields_not_assigned.select do |field|
        model.__send__(field).nil?
      end
    end

    fields_not_assigned
  end

  # Called to apply this operation. The model, create_options and tags
  # arguments can be specified to provide more context.
  def apply!(model, create_options, tags)
    _assignments = assignments(model, create_options, tags)

    return if (_assignments === false)

    value = nil

    # The defined blocks are tried in sequence until one of them returns
    # a non-nil value.    
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

    return unless (_assignments)

    model and !value.nil? and _assignments.each do |field|
      next unless (field)
      
      model.__send__(:"#{field}=", value)
    end
  end

protected
  def flatten_any(array)
    array = [ array ].flatten.compact.collect(&:to_sym)

    return unless (array.any?)

    array
  end

  def assign_block_options!(options)
    return unless (options[:block])

    @blocks << options[:block]
  end

  def assign_fields_options!(options)
    @fields = options[:fields]

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
    if (only_options = options[:only])
      @only = flatten_any(only_options)
    end
  end

  def assign_except_options!(options)
    if (except_options = options[:except])
      @except = flatten_any(except_options)
    end
  end

  def assign_after_options!(options)
    if (after_option = options[:after])
      @after = after_option
    end
  end

  def assign_force_options!(options)
    if (options[:force])
      @force = options[:force]
    end
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
    from = options[:from]

    return unless (from)

    case (from)
    when Proc
      @from = from

      return
    when Array
      from.collect(&:to_sym)
    when Hash
      from = from.to_a
    when String
      from = from.split('.')
    else
      raise TestDummy::Exception, "Argument to :from must be a String, Array or Hash."
    end

    @blocks << lambda do |model|
      from.inject(model) do |_model, _method|
        _model ? _model.send(_method) : nil
      end
    end
  end

  def block_for_inherit_options(spec)
    case (spec)
    when Proc
      return spec
    when Array
      spec.collect(&:to_sym)
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

    @inherited_attributes =
      inherit.collect do |attribute, spec|
        [
          attribute.to_sym,
          block_for_inherit_options(spec)
        ]
      end
  end

  def assign_reflection_block!(options)
    return unless (@model_class)

    @blocks <<
      if (@inherited_attributes)
        lambda do |model|
          @model_class.create_dummy do |reflection_model|
            @inherited_attributes.each do |attribute, proc|
              reflection_model.send("#{attribute}=", proc.call(model))
            end
          end
        end
      else
        lambda do |model|
          @model_class.create_dummy
        end
      end
  end

  def assign_default_block!(options)
    return if (@blocks.any? or !@fields or @fields.empty?)

    @fields.each do |field|
      next unless (field and TestDummy::Helper.respond_to?(field))

      @blocks << lambda do |model|
        TestDummy::Helper.send(field)
      end
    end
  end
end
