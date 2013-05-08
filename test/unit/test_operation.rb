require File.expand_path('../helper', File.dirname(__FILE__))

class TestOperation < Test::Unit::TestCase
  class MockModelExample
    attr_accessor :field
    attr_accessor :field_id
    attr_accessor :root_id

    def self.create_dummy(*args)
      self.new(*args)
    end

    def initialize(options = nil)
      @field = options && options[:field]
      @field_id = options && options[:field_id]
      @root_id = options && options[:root_id]
    end
  end

  def test_defaults
    operation = TestDummy::Operation.new({ })

    assert_equal [ nil ], operation.fields
    assert_equal [ ], operation.source_keys
    assert_equal [ ], operation.source_methods
    assert_equal nil, operation.only
    assert_equal nil, operation.except
    assert_equal nil, operation.model_class
    assert_equal nil, operation.foreign_key
  end

  def test_with_fields
    operation = TestDummy::Operation.new(
      :fields => [ :field, :field_id ]
    )

    assert_equal [ :field, :field_id ], operation.fields
  end

  def test_block_with_only_tags
    triggered = 0

    operation = TestDummy::Operation.new(
      :only => [ :test_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal [ :test_tag ], operation.only
    assert_equal nil, operation.except

    assert_equal [ ], operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    assert_equal [ nil ], operation.assignments(nil, { }, [ :test_tag ])

    operation.apply!(nil, { }, [ :test_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_only_tags_with_fields
    triggered = 0

    operation = TestDummy::Operation.new(
      :fields => [ :test_field ],
      :only => [ :test_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal [ :test_tag ], operation.only
    assert_equal nil, operation.except

    assert_equal [ ], operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    assert_equal [ :test_field ], operation.assignments(nil, { }, [ :test_tag ])

    operation.apply!(nil, { }, [ :test_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_model_on_multiple_fields
    index = 0

    operation = TestDummy::Operation.new(
      :fields => [ :field_id, :root_id ],
      :block => lambda { index += 1 }
    )

    model = MockModelExample.new

    operation.apply!(model, { }, [ ])

    assert_equal 1, index

    assert_equal 1, model.field_id
    assert_equal 1, model.root_id
  end

  def test_block_without_model
    triggered = 0
    block = lambda { triggered += 1 }

    operation = TestDummy::Operation.new(
      :block => block
    )

    operation.apply!(nil, { }, [ ])

    assert_equal 1, triggered
  end

  def test_block_without_option_specified
    triggered = false
    block = lambda { triggered = :set }
    model = MockModelExample.new

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :block => block
    )

    operation.apply!(model, { }, [ ])

    assert_equal :set, triggered

    assert_equal :set, model.field
  end

  def test_block_with_option_specified
    triggered = false
    block = lambda { triggered = :set }
    model = MockModelExample.new(:field => nil)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :block => block
    )

    operation.apply!(model, { :field => true }, [ ])

    assert_equal false, triggered

    assert_equal nil, model.field
  end

  def test_block_with_model_set
    triggered = false
    block = lambda { triggered = :set }
    model = MockModelExample.new(:field => :default)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :block => block
    )

    operation.apply!(model, { :field => true }, [ ])

    assert_equal false, triggered

    assert_equal :default, model.field
  end

  def test_block_without_model_set
    triggered = false
    block = lambda { triggered = :set }
    model = MockModelExample.new

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :block => block
    )

    operation.apply!(model, { }, [ ])

    assert_equal :set, triggered

    assert_equal :set, model.field
  end

  def test_block_with_model_reflection_attribute_set
    triggered = false
    block = lambda { triggered = 0 }
    model = MockModelExample.new(:field => :reference)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :foreign_key => :field_id,
      :block => block
    )

    assert_equal [ :field, 'field', :field_id, 'field_id' ], operation.source_keys
    assert_equal [ :field, :field_id ], operation.source_methods

    operation.apply!(model, { }, [ ])

    assert_equal false, triggered

    assert_equal :reference, model.field
  end

  def test_block_with_model_foreign_key_set
    triggered = false
    block = lambda { triggered = 0 }
    model = MockModelExample.new(:field_id => 1)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :foreign_key => :field_id,
      :block => block
    )

    assert_equal [ :field, 'field', :field_id, 'field_id' ], operation.source_keys
    assert_equal [ :field, :field_id ], operation.source_methods

    assert_equal [ ], operation.assignments(model, { }, [ ])

    operation.apply!(model, { }, [ ])

    assert_equal false, triggered

    assert_equal 1, model.field_id
  end

  def test_block_with_model_inheritance_as_symbol
    model = MockModelExample.new(:root_id => 1)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :inherit => :root_id,
      :model_class => MockModelExample,
      :foreign_key => :field_id
    )

    assert_equal [ :field, 'field', :field_id, 'field_id' ], operation.source_keys
    assert_equal [ :field, :field_id ], operation.source_methods

    assert_equal [ :field ], operation.assignments(model, { }, [ ])

    operation.apply!(model, { }, [ ])

    assert model.field

    assert_equal 1, model.field.root_id
  end

  def test_block_with_model_inheritance_as_hash
    model = MockModelExample.new(:root_id => 1)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :inherit => { :root_id => [ :root_id ] },
      :model_class => MockModelExample,
      :foreign_key => :field_id
    )

    assert_equal [ :field, 'field', :field_id, 'field_id' ], operation.source_keys
    assert_equal [ :field, :field_id ], operation.source_methods

    assert_equal [ :field ], operation.assignments(model, { }, [ ])

    operation.apply!(model, { }, [ ])

    assert model.field

    assert_equal 1, model.field.root_id
  end
end