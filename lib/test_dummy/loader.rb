class TestDummy::Loader
  # == Class Methods ========================================================
  
  def self.load!(model_class)
    @instance ||= new

    @instance[model_class.to_s]
  end

  # == Instance Methods =====================================================

  def initialize
    @loaded = { }
  end

  def [](class_name)
    return @loaded[class_name] if (@loaded.key?(class_name))

    @loaded[class_name] = nil

    dummy_path = File.expand_path(
     "#{class_name.to_s.underscore}.rb",
      TestDummy.dummy_extensions_path
    )

    if (File.exist?(dummy_path))
      begin
        Kernel.load(dummy_path)

        @loaded[class_name] = true
      rescue LoadError => e
        @loaded[class_name] = e
      end
    else
      @loaded[class_name] = false
    end
  rescue LoadError => e
    # Persist that this load attempt failed and don't retry later.
    @loaded[class_name] = e
  end
end
