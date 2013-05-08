module TestDummy::Support
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
        (reflection[:key] || "#{attribute.to_s.underscore}_id").to_sym
      ]
    end
  end
end
