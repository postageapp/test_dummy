module TestDummy
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
  end
  
  def self.combine_create_params(*param_sets)
    final_params = { }
    
    # Apply param_sets in order they are listed
    param_sets.compact.each do |params|
      params.each do |k, v|
        # Ignore nil assignments
        final_params[k.to_sym] = v if (v)
      end
    end

    final_params
  end
  
  def self.add_module(new_module)
    FakeMethods.send(:extend, new_module)
  end
  
  def self.can_fake(*names, &block)
    case (names.last)
    when Hash
      options = names.pop
    end
    
    if (options and options[:with])
      block = options[:with]
    end

    FakeMethods.send(
      :extend,
      names.inject(Module.new) do |m, name|
        m.send(:define_method, name, &block)
        m
      end
    )
  end
  
  def self.config(&block)
    RailsModelFaker.instance_eval(&block)
  end
  
  def self.include(addon)
    RailsModelFaker.send(:extend, addon)
  end
  
  module FakeMethods
    # Placeholder for generic fake methods
  end
  
  module ClassMethods
    def fake_field_config
      @rmf_can_fake ||= { }
    end
    
    def can_fake(*names, &block)
      options = nil

      case (names.last)
      when Hash
        options = names.pop
      end
      
      if (options and options[:with])
        block = options[:with]
      end
      
      @rmf_can_fake ||= { }
      @rmf_can_fake_order ||= [ ]
      
      names.flatten.each do |name|
        name = name.to_sym

        # For associations, delay creation of block until first call
        # to allow for additional relationships to be defined after
        # the can_fake call. Leave placeholder (true) instead.

        @rmf_can_fake[name] = block || true
        @rmf_can_fake_order << name
      end
    end
    
    def can_fake?(*names)
      @rmf_can_fake ||= { }
      
      names.flatten.reject do |name|
        @rmf_can_fake.key?(name)
      end.empty?
    end
    
    def build_fake(params = nil)
      model = new(RailsModelFaker.combine_create_params(scope(:create), params))

      yield(model) if (block_given?)

      self.execute_fake_operation(model, params)
      
      model
    end
    
    def create_fake(params = nil, &block)
      model = build_fake(params, &block)
      
      model.save
      
      model
    end

    def create_fake!(params = nil, &block)
      model = build_fake(params, &block)
      
      model.save!
      
      model
    end
    
    def fake(name, params = nil)
      params = RailsModelFaker.combine_create_params(scope(:create), params)
      
      fake_method_call(nil, params, fake_method(name))
    end
    
    def fake_params(params = nil)
      params = RailsModelFaker.combine_create_params(scope(:create), params)
      
      @rmf_can_fake_order.each do |field|
        unless (params.key?(field))
          result = fake(field, params)
          
          case (result)
          when nil, params
            # Declined to populate parameters if method returns nil
            # or returns the existing parameter set.
          else
            params[field] = result
          end
        end
      end
      
      params
    end
    
    def execute_fake_operation(model, params = nil)
      @rmf_can_fake_order.each do |name|
        if (reflection = reflect_on_association(name))
          unless ((params and params.key?(name.to_sym)) or model.send(name))
            model.send(:"#{name}=", fake_method_call(model, params, fake_method(name)))
          end
        else
          unless (params and (params.key?(name.to_sym) or params.key?(name.to_s)))
            model.send(:"#{name}=", fake_method_call(model, params, fake_method(name)))
          end
        end
      end
      
      model
    end
    
  protected
    def fake_method_call(model, params, block)
      case (block.arity)
      when 2, -1
        block.call(model, params)
      when 1
        block.call(model)
      else
        block.call
      end
    end
    
    def fake_method(name)
      name = name.to_sym
      
      block = @rmf_can_fake[name]

      case (block)
      when Module
        block.method(name)
      when Symbol
        FakeMethods.method(name)
      when true
        # Configure association faker the first time it is called
        if (reflection = reflect_on_association(name))
          primary_key = reflection.primary_key_name.to_sym

          @rmf_can_fake[name] =
            lambda do |model, params|
              (params and params.key?(primary_key)) ? nil : reflection.klass.send(:create_fake)
            end
        else
          raise "Cannot fake unknown relationship #{name}"
        end
      else
        block
      end
    end
  end
  
  module InstanceMethods
    def fake!(params = nil)
      self.class.execute_fake_operation(self, params)
    end
  end
end
