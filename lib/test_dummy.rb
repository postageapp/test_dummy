module TestDummy
  # == Submodules ============================================================

  autoload(:Definition, 'test_dummy/definition')
  autoload(:Helper, 'test_dummy/helper')
  autoload(:Loader, 'test_dummy/loader')
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

  # This is called when this module is included.
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
  end
  
  # Used to dynamically declare extensions on a particular class. Has the
  # effect of executing the block in the context of the class given.
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
      @dummy_definition ||= TestDummy::Definition.new

      TestDummy::Loader.load!(self)

      @dummy_definition
    end
    
    # Declares how to fake one or more attributes. Accepts a block
    # that can receive up to two parameters, the first the instance of
    # the model being created, the second the parameters supplied to create
    # it. The first and second parameters may be nil.
    def dummy(*fields)
      options =
        case (fields.last)
        when Hash
           fields.pop
         else
          { }
        end

      if (block_given?)
        options = options.merge(block: Proc.new)
      end

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
    def build_dummy(create_attributes = nil, tags = nil)
      build_scope = where(nil)

      create_attributes = TestDummy::Support.combine_attributes(build_scope, create_attributes)

      model = new(create_attributes)

      yield(model) if (block_given?)

      self.dummy_definition.apply!(model, create_attributes, tags)

      model
    end
    
    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed and the model is saved. Returns a
    # dummy model. The model may not have been saved if there was a
    # validation failure, or if it was blocked by a callback.
    def create_dummy(*tags, &block)
      if (tags.last.is_a?(Hash))
        create_attributes = tags.pop
      end

      model = build_dummy(create_attributes, tags, &block)

      model.save

      self.dummy_definition.apply_after_save!(model, create_attributes, tags)
      
      model
    end

    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed and the model is saved. Returns a
    # dummy model. Will throw ActiveRecord::RecordInvalid if there was al20
    # validation failure, or ActiveRecord::RecordNotSaved if the save was
    # blocked by a callback.
    def create_dummy!(*tags, &block)
      if (tags.last.is_a?(Hash))
        create_attributes = tags.pop
      end

      model = build_dummy(create_attributes, tags, &block)
      
      model.save!
      
      self.dummy_definition.apply_after_save!(model, create_attributes, tags)

      model
    end
  end
  
  module InstanceMethods
    # Assigns any attributes which can be dummied that have not already
    # been populated.
    def dummy!(create_attributes = nil, tags = nil)
      self.class.dummy_definition.apply!(self, create_attributes, tags)
    end
  end
end
