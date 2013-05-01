module TestDummy
  if (defined?(Rails))
    # Only load the Railtie if Rails is loaded.
    require 'test_dummy/railtie'
  end

  class Exception < ::Exception
  end

  autoload(:Helper, File.expand_path('test_dummy/helper', File.dirname(__FILE__)))
  autoload(:TestHelper, File.expand_path('test_dummy/test_helper', File.dirname(__FILE__)))

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
  
  module Support
    # Combines several sets of parameters together into a single set in order
    # of lowest priority to highest priority. Supplied list can contain nil
    # values which will be ignored. Returns a Hash with symbolized keys.
    def self.combine_attributes(*sets)
      combined_attributes = { }
    
      # Apply sets in order they are listed
      sets.compact.each do |set|
        set.each do |k, v|
          case (v)
          when nil
            # Ignore nil assignments
          else
            combined_attributes[k.to_sym] = v
          end
        end
      end

      combined_attributes
    end

    # This method is used to provide a unified interface to the otherwise
    # irregular methods to discover information on assocations. Rails 3
    # introduces a new method. Returns the reflected class and foreign key
    # properties for a named attribute, or nil if no association could be found.
    def self.reflection_properties(model_class, attribute)
      if (model_class.respond_to?(:reflect_on_association) and reflection = model_class.reflect_on_association(attribute))
        [
          reflection.klass,
          (reflection.respond_to?(:foreign_key) ? reflection.foreign_key : reflection.primary_key_name).to_sym
        ]
      elsif (model_class.respond_to?(:association_reflection) and reflection = model_class.association_reflection(attribute))
        [
          reflection[:associated_class],
          reflection[:key] || :"#{attribute.to_s.underscore}_id"
        ]
      end
    end
  end

  # Adds a mixin to the core Helper module
  def self.add_module(new_module)
    Helper.send(:extend, new_module)
  end

  # Used to configure defaults or aliases that can be used by all definitions.
  # Takes a block that should call definition methods like `dummy`.
  def self.define(&block)
    instance_eval(&block)
  end
  
  # Used in an initializer to define things that can be dummied by all
  # models if these properties are available.
  def self.dummy(*names, &block)
    case (names.last)
    when Hash
      options = names.pop
    end
    
    if (options and options[:with])
      with = options[:with]

      names.each do |name|
        if (Helper.respond_to?(with))
          Helper.send(:alias_method, name, with)
        else
          Helper.send(:define_method, name) do
            send(with)
          end
        end
      end
    else
      names.each do |name|
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
    def dummy_attributes
      @test_dummy ||= { }
    end
    
    # Declares how to fake one or more attributes. Accepts a block
    # that can receive up to two parameters, the first the instance of
    # the model being created, the second the parameters supplied to create
    # it. The first and second parameters may be nil.
    def dummy(*names, &block)
      options = nil

      case (names.last)
      when Hash
        options = names.pop
      end
      
      @test_dummy ||= { }
      @test_dummy_order ||= [ ]
      
      names.flatten.each do |name|
        name = name.to_sym
        from = nil
        create_options_proc = nil

        if (options)
          if (options[:with])
            if (block)
              raise TestDummy::Exception, "Cannot use block and :with option at the same time."
            end

            block =
              case (with = options[:with])
              when Proc
                with
              when String, Symbol
                lambda { send(with) }
              else
                lambda { with }
              end
          end

          # The :inherit directive is used to pass arguments through to the
          # create_dummy call on the association's class.
          if (inherit = options[:inherit])
            inherit_options = Hash[
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
              inherit_options.each do |attribute, spec|
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

          block = lambda do |model, with_attributes|
            reflection_class, foreign_key = TestDummy::Support.reflection_properties(self, name)

            if (reflection_class and foreign_key)
              unless ((with_attributes and (with_attributes.key?(name) or with_attributes.key?(foreign_key))) or model.send(name).present?)
                object = from && from.inject(model) do |_model, _method|
                  _model ? _model.send(_method) : nil
                end

                object ||=
                  reflection_class.create_dummy(with_attributes) do |target|
                    if (create_options_proc)
                      create_options_proc.call(target, model, with_attributes)
                    end
                  end

                model.send(:"#{name}=", object)
              end
            end
          end
        end

        # For associations, delay creation of block until first call
        # to allow for additional relationships to be defined after
        # the to_dummy call. Leave placeholder (true) instead.

        @test_dummy[name] = block || true
        @test_dummy_order << name
      end
    end
    
    # Returns true if all the supplied attribute names have defined
    # dummy methods, or false otherwise.
    def can_dummy?(*names)
      @test_dummy ||= { }
      
      names.flatten.reject do |name|
        @test_dummy.key?(name)
      end.empty?
    end
    
    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed. Returns a dummy model which has not
    # been saved.
    def build_dummy(with_attributes = nil)
      load_dummy_declaration!
      
      build_scope = (method(:scoped).arity == 1) ? scoped(nil).scope(:create) : scoped.scope_for_create

      model = new(TestDummy::Support.combine_attributes(build_scope, with_attributes))

      yield(model) if (block_given?)

      self.execute_dummy_operation(model, with_attributes)
      
      model
    end
    
    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed and the model is saved. Returns a
    # dummy model. The model may not have been saved if there was a
    # validation failure, or if it was blocked by a callback.
    def create_dummy(with_attributes = nil, &block)
      model = build_dummy(with_attributes, &block)
      
      model.save
      
      model
    end

    # Builds a dummy model with some parameters set as supplied. The
    # new model is provided to the optional block for manipulation before
    # the dummy operation is completed and the model is saved. Returns a
    # dummy model. Will throw ActiveRecord::RecordInvalid if there was al20
    # validation failure, or ActiveRecord::RecordNotSaved if the save was
    # blocked by a callback.
    def create_dummy!(with_attributes = nil, &block)
      model = build_dummy(with_attributes, &block)
      
      model.save!
      
      model
    end
    
    # Produces dummy data for a single attribute.
    def dummy_attribute(name, with_attributes = nil)
      with_attributes = TestDummy.combine_attributes(scoped.scope_for_create, with_attributes)
      
      dummy_method_call(nil, with_attributes, dummy_method(name))
    end
    
    # Produces a complete set of dummy attributes. These can be used to
    # create a model.
    def dummy_attributes(with_attributes = nil)
      with_attributes = TestDummy.combine_attributes(scoped.scope_for_create, with_attributes)
      
      @test_dummy_order.each do |field|
        unless (with_attributes.key?(field))
          result = dummy(field, with_attributes)
          
          case (result)
          when nil, with_attributes
            # Declined to populate parameters if method returns nil
            # or returns the existing parameter set.
          else
            with_attributes[field] = result
          end
        end
      end
      
      with_attributes
    end
    
    # This performs the dummy operation on a model with an optional set
    # of parameters.
    def execute_dummy_operation(model, with_attributes = nil)
      load_dummy_declaration!
      
      return model unless (@test_dummy_order)
      
      @test_dummy_order.each do |name|
        if (respond_to?(:reflect_on_association) and reflection = reflect_on_association(name))
          foreign_key = (reflection.respond_to?(:foreign_key) ? reflection.foreign_key : reflection.primary_key_name).to_sym
          
          unless ((with_attributes and (with_attributes.key?(name.to_sym) or with_attributes.key?(foreign_key.to_sym))) or model.send(name).present?)
            model.send(:"#{name}=", dummy_method_call(model, with_attributes, dummy_method(name)))
          end
        elsif (respond_to?(:association_reflection) and reflection = association_reflection(name))
          key = reflection[:key] || :"#{name.to_s.underscore}_id"

          unless ((with_attributes and (with_attributes.key?(name.to_sym) or with_attributes.key?(key.to_sym))) or model.send(name).present?)
            model.send(:"#{name}=", dummy_method_call(model, with_attributes, dummy_method(name)))
          end
        else
          unless (with_attributes and (with_attributes.key?(name.to_sym) or with_attributes.key?(name.to_s)))
            model.send(:"#{name}=", dummy_method_call(model, with_attributes, dummy_method(name)))
          end
        end
      end
      
      model
    end
    
  protected
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
    def dummy!(with_attributes = nil)
      self.class.execute_dummy_operation(self, with_attributes)
    end
  end
end
