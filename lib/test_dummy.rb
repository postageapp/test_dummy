module TestDummy
  # == Submodules ============================================================

  autoload(:Definition, 'test_dummy/definition')
  autoload(:Helper, 'test_dummy/helper')
  autoload(:Operation, 'test_dummy/operation')
  autoload(:Support, 'test_dummy/support')
  autoload(:TestHelper, 'test_dummy/test_helper')

  # == Rails Hook ============================================================

  # Only load the Railtie if Rails is loaded.
  if (defined?(Rails))
    require 'test_dummy/railtie'
  end

  # == Utility Classes ======================================================

  # TestDummy::Exception is thrown instead of the master exception type.
  class Exception < ::Exception
  end

  # == Module Methods =======================================================

  # Returns the current path used to load dummy extensions into models, or
  # nil if no path is currently defined. Defaults to "test/dummy" off of the
  # Rails root if Rails is available.
  def self.dummy_extensions_path
    @dummy_extensions_path ||= begin
      if (defined?(Rails))
        File.expand_path('test/dummy', Rails.root)
      else
        nil
      end
    end
  end
  
  # Defines the dummy extension path. The full path to the destination should
  # be specified.
  def self.dummy_extensions_path=(value)
    @dummy_extensions_path = value
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
  end
  
  def self.declare(on_class, &block)
    on_class.instance_eval(&block)
  end

  # Adds a mixin to the core Helper module
  def self.add_module(new_module)
    Helper.send(:extend, new_module)
  end

  # Used to configure defaults or aliases that can be used by all operations.
  # Takes a block that should call definition methods like `dummy`.
  def self.define(&block)
    instance_eval(&block)
  end
  
  # Used in an initializer to define things that can be dummied by all
  # models if these properties are available.
  def self.dummy(*fields, &block)
    case (fields.last)
    when Hash
      options = fields.pop
    end
    
    # REFACTOR: Adapt to new Operation style
    if (options and options[:with])
      with = options[:with]

      fields.each do |name|
        if (Helper.respond_to?(with))
          Helper.send(:alias_method, name, with)
        else
          Helper.send(:define_method, name) do
            send(with)
          end
        end
      end
    else
      fields.each do |name|
        Helper.send(:define_method, name, &block)
      end
    end
  end
  
  # Used in an initializer to define configuration parameters.
  def self.config(&block)
    TestDummy.instance_eval(&block)
  end
  
  module ClassMethods
    # Returns a Hash which describes the dummy configuration for this
    # Model class.
    def dummy_definition
      @test_dummy ||= TestDummy::Definition.new
    end
    
    # Declares how to fake one or more attributes. Accepts a block
    # that can receive up to two parameters, the first the instance of
    # the model being created, the second the parameters supplied to create
    # it. The first and second parameters may be nil.
    def dummy(*fields)
      options = nil

      case (fields.last)
      when Hash
        options = fields.pop
      end

      if (block_given?)
        options = options.merge(:block => Proc.new)
      end

      fields = fields.flatten.collect(&:to_sym)

      self.dummy_definition.define_operation(self, fields, options)
    end
    
    # Returns true if all the supplied attribute fields have defined
    # dummy methods, or false otherwise.
    def can_dummy?(*fields)
      @test_dummy and @test_dummy.can_dummy?(*fields) or false
    end
    
    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed. Returns a dummy model which has not
    # been saved.
    def build_dummy(with_attributes = nil, tags = nil)
      load_dummy_declaration!
      
      build_scope = (method(:scoped).arity == 1) ? scoped(nil).scope(:create) : scoped.scope_for_create

      with_attributes = TestDummy::Support.combine_attributes(build_scope, with_attributes)

      model = new(with_attributes)

      yield(model) if (block_given?)

      self.execute_dummy_operation(model, with_attributes, tags)
      
      model
    end
    
    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed and the model is saved. Returns a
    # dummy model. The model may not have been saved if there was a
    # validation failure, or if it was blocked by a callback.
    def create_dummy(*args, &block)
      if (args.last.is_a?(Hash))
        with_attributes = args.pop
      end

      model = build_dummy(with_attributes, args, &block)
      
      model.save
      
      model
    end

    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed and the model is saved. Returns a
    # dummy model. Will throw ActiveRecord::RecordInvalid if there was al20
    # validation failure, or ActiveRecord::RecordNotSaved if the save was
    # blocked by a callback.
    def create_dummy!(*args, &block)
      if (args.last.is_a?(Hash))
        with_attributes = args.pop
      end

      model = build_dummy(with_attributes, args, &block)
      
      model.save!
      
      model
    end

  protected
    # This performs the dummy operation on a model with an optional set
    # of parameters.
    def execute_dummy_operation(model, with_attributes = nil, tags = nil)
      load_dummy_declaration!
      
      return model unless (@test_dummy_order)

      @test_dummy.each do |definition|
        assignments = nil

        if (fields = definition[:fields])
          assignments = fields.select do |field|
            if (respond_to?(:reflect_on_association) and reflection = reflect_on_association(field))
              foreign_key = (reflection.respond_to?(:foreign_key) ? reflection.foreign_key : reflection.primary_key_field).to_sym
              
              (with_attributes and (with_attributes.key?(field.to_sym) or with_attributes.key?(foreign_key.to_sym))) or model.send(field).present?
            elsif (respond_to?(:association_reflection) and reflection = association_reflection(field))
              key = reflection[:key] || :"#{field.to_s.underscore}_id"

              (with_attributes and (with_attributes.key?(field.to_sym) or with_attributes.key?(key.to_sym))) or model.send(field).present?
            else
              (with_attributes and (with_attributes.key?(field.to_sym) or with_attributes.key?(field.to_s)))
            end
          end
        else
          assignments = false
        end

        unless (assignments.nil?)
          value = dummy_method_call(model, with_attributes, definition)

          assignments and assignments.each do |field|
            next unless (field)

            model.send(:"#{field}=", value)
          end
        end
      end
      
      model
    end
    
    def load_dummy_declaration!
      return unless (@_dummy_module.nil?)

      @_dummy_module =
        begin
          dummy_path = File.expand_path(
           "#{name.underscore}.rb",
            TestDummy.dummy_extensions_path
          )
      
          if (File.exist?(dummy_path))
            load(dummy_path)
          end
        rescue LoadError
          # Persist that this load attempt failed and don't retry later.
          false
        end
    end

    def dummy_method_call(model, with_attributes, block)
      case (block.arity)
      when 2
        block.call(model, with_attributes)
      when 1
        block.call(model)
      else
        model.instance_eval(&block)
      end
    end
    
    def dummy_method(name)
      name = name.to_sym
      
      block = @test_dummy[name]

      case (block)
      when Module
        block.method(name)
      when Symbol
        Helper.method(name)
      when true
        # Configure association dummy the first time it is called
        if (respond_to?(:reflect_on_association) and reflection = reflect_on_association(name))
          foreign_key = (reflection.respond_to?(:foreign_key) ? reflection.foreign_key : reflection.primary_key_name).to_sym

          @test_dummy[name] =
            lambda do |model, with_attributes|
              (with_attributes and (with_attributes.key?(foreign_key) or with_attributes.key?(name))) ? nil : reflection.klass.send(:create_dummy)
            end
        elsif (respond_to?(:association_reflection) and reflection = association_reflection(name))
          key = reflection[:key] || :"#{name.to_s.underscore}_id"

          @test_dummy[name] =
            lambda do |model, with_attributes|
              (with_attributes and (with_attributes.key?(key) or with_attributes.key?(name))) ? nil : reflection[:associated_class].send(:create_dummy)
            end
        elsif (TestDummy::Helper.respond_to?(name))
          @test_dummy[name] = lambda do |model, with_attributes|
            TestDummy::Helper.send(name)
          end
        else
          raise "Cannot dummy unknown relationship #{name}"
        end
      else
        block
      end
    end
  end
  
  module InstanceMethods
    # Assigns any attributes which can be dummied that have not already
    # been populated.
    def dummy!(with_attributes = nil, tags = nil)
      self.class.execute_dummy_operation(self, with_attributes, tags)
    end
  end
end
