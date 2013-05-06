module TestDummy
  # == Submodules ============================================================

  autoload(:Helper, 'test_dummy/helper')
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
      @test_dummy_tags ||= { }
      
      names.flatten.each do |name|
        name = name.to_sym
        from = nil
        create_options_proc = nil

        if (options)
          if (options[:only])
            tags = [ options[:only] ].flatten.compact
              
            if (tags.any?)
              set = @test_dummy_tags[name] ||= { }
              
              set[:only] = tags
            end
          end

          if (options[:except])
            tags = [ options[:except] ].flatten.compact
              
            if (tags.any?)
              set = @test_dummy_tags[name] ||= { }
              
              set[:except] = tags
            end
          end

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

          reflection_class, foreign_key = TestDummy::Support.reflection_properties(self, name)

          if (reflection_class and foreign_key)
            block = lambda do |model, with_attributes|
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
    def build_dummy(with_attributes = nil, tags = nil)
      load_dummy_declaration!
      
      build_scope = (method(:scoped).arity == 1) ? scoped(nil).scope(:create) : scoped.scope_for_create

      model = new(TestDummy::Support.combine_attributes(build_scope, with_attributes))

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
    
    # Produces dummy data for a single attribute.
    def dummy_attribute(name, with_attributes = nil)
      with_attributes = TestDummy.combine_attributes(scoped.scope_for_create, with_attributes)
      
      dummy_method_call(nil, with_attributes, dummy_method(name))
    end
    
    # Produces a complete set of dummy attributes. These can be used to
    # create a model.
    def dummy_attributes(with_attributes = nil, tags = nil)
      with_attributes = TestDummy.combine_attributes(scoped.scope_for_create, with_attributes)
      
      @test_dummy_order.each do |field|
        next if (with_attributes.key?(field))

        if (when_tagged = @test_dummy_when[field])
          next if (!tags or (tags & when_tagged).empty?)
        end

        result = dummy(field, with_attributes)
        
        case (result)
        when nil, with_attributes
          # Declined to populate parameters if method returns nil
          # or returns the existing parameter set.
        else
          with_attributes[field] = result
        end
      end
      
      with_attributes
    end
    
    # This performs the dummy operation on a model with an optional set
    # of parameters.
    def execute_dummy_operation(model, with_attributes = nil, tags = nil)
      load_dummy_declaration!
      
      return model unless (@test_dummy_order)

      @test_dummy_order.each do |name|
        if (tag_conditions = @test_dummy_tags[name])
          if (required_tags = tag_conditions[:only])
            next if (!tags or (tags & required_tags).empty?)
          end

          if (excluding_tags = tag_conditions[:except])
            next if (tags and (tags & excluding_tags).any?)
          end
        end

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
