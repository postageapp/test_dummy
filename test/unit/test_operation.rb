require_relative '../helper'

class TestOperation < MiniTest::Unit::TestCase
  class MockModelExample
    COLUMNS = [
      :field,
      :field_id,
      :root_id,
      :integer
    ].freeze

    attr_accessor *COLUMNS
    attr_reader :changed
    attr_accessor :temporary

    def self.column_names
      COLUMNS.collect(&:to_s)
    end

    def self.create_dummy(*args)
      created_dummy = self.new(*args)

      yield(created_dummy) if (block_given?)

      created_dummy
    end

    def initialize(options = nil)
      @field = options && options[:field]
      @field_id = options && options[:field_id]
      @integer = options && options[:integer].to_i || 0

      # root_id is not "accessible"
      
      @changed = options && options.keys.collect(&:to_s) || [ ]
   end
  end

  def test_defaults
    operation = TestDummy::Operation.new({ })

    assert_equal nil, operation.fields
    assert_equal [ ], operation.source_keys
    assert_equal [ ], operation.source_methods
    assert_equal nil, operation.after
    assert_equal nil, operation.only
    assert_equal nil, operation.except
    assert_equal nil, operation.model_class
    assert_equal nil, operation.foreign_key
  end

  def test_with_option
    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :with => :random_string
    )

    assert_equal true, TestDummy::Helper.respond_to?(:random_string)

    model = MockModelExample.new

    operation.apply!(model, { }, [ ])

    assert model.field
    assert_equal 12, model.field.length
  end

  def test_with_after
    triggered = 0
    operation = TestDummy::Operation.new(
      :block => lambda { triggered += 1 },
      :after => :save
    )

    assert_equal :save, operation.after

    assert_equal 0, triggered

    operation.apply!(nil, { }, [ ])

    assert_equal 1, triggered
  end

  def test_with_fields
    operation = TestDummy::Operation.new(
      :fields => [ :field, :field_id ]
    )

    assert_equal [ :field, :field_id ], operation.fields
  end

  def test_with_after
    operation = TestDummy::Operation.new(
      :after => :save
    )

    assert_equal :save, operation.after
  end

  def test_block_with_only_tag
    triggered = 0

    operation = TestDummy::Operation.new(
      :only => :test_tag,
      :block => lambda { triggered += 1 }
    )

    assert_equal [ ], operation.fields(nil)
    assert_equal [ ], operation.fields([ ])
    assert_equal nil, operation.fields([ :test_tag ])

    assert_equal [ :test_tag ], operation.only
    assert_equal nil, operation.except

    assert_equal false, operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    assert_equal nil, operation.assignments(nil, { }, [ :test_tag ])

    operation.apply!(nil, { }, [ :test_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_multiple_only_tags
    triggered = 0

    operation = TestDummy::Operation.new(
      :only => [ :first_tag, :second_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal [ ], operation.fields(nil)
    assert_equal [ ], operation.fields([ ])
    assert_equal nil, operation.fields([ :first_tag ])
    assert_equal nil, operation.fields([ :second_tag ])
    assert_equal nil, operation.fields([ :first_tag, :second_tag ])

    assert_equal [ :first_tag, :second_tag ], operation.only
    assert_equal nil, operation.except

    assert_equal false, operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    assert_equal nil, operation.assignments(nil, { }, [ :first_tag ])
    assert_equal nil, operation.assignments(nil, { }, [ :second_tag ])
    assert_equal nil, operation.assignments(nil, { }, [ :first_tag, :second_tag ])
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

    assert_equal false, operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    assert_equal [ :test_field ], operation.assignments(nil, { }, [ :test_tag ])

    operation.apply!(nil, { }, [ :test_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_except_tags
    triggered = 0

    operation = TestDummy::Operation.new(
      :except => [ :test_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal nil, operation.only
    assert_equal [ :test_tag ], operation.except

    assert_equal nil, operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 1, triggered

    assert_equal false, operation.assignments(nil, { }, [ :test_tag ])

    operation.apply!(nil, { }, [ :test_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_except_tags_with_fields
    triggered = 0

    operation = TestDummy::Operation.new(
      :fields => [ :test_field ],
      :except => [ :test_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal nil, operation.only
    assert_equal [ :test_tag ], operation.except

    assert_equal [ :test_field ], operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 1, triggered

    assert_equal false, operation.assignments(nil, { }, [ :test_tag ])

    operation.apply!(nil, { }, [ :test_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_only_and_except_tags
    triggered = 0

    operation = TestDummy::Operation.new(
      :only => [ :only_tag ],
      :except => [ :except_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal [ :only_tag ], operation.only
    assert_equal [ :except_tag ], operation.except

    assert_equal false, operation.assignments(nil, { }, [ ])
    assert_equal nil, operation.assignments(nil, { }, [ :only_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :except_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :only_tag, :except_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :except_tag, :only_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :except_tag, :only_tag, :irrelevant_tag ])
    assert_equal nil, operation.assignments(nil, { }, [ :only_tag, :irrelevant_tag ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    operation.apply!(nil, { }, [ :only_tag ])

    assert_equal 1, triggered

    operation.apply!(nil, { }, [ :except_tag ])

    assert_equal 1, triggered

    operation.apply!(nil, { }, [ :only_tag, :except_tag ])

    assert_equal 1, triggered
  end

  def test_block_with_only_and_except_tags_with_fields
    triggered = 0

    operation = TestDummy::Operation.new(
      :fields => [ :test_field ],
      :only => [ :only_tag ],
      :except => [ :except_tag ],
      :block => lambda { triggered += 1 }
    )

    assert_equal [ :only_tag ], operation.only
    assert_equal [ :except_tag ], operation.except

    assert_equal false, operation.assignments(nil, { }, [ ])

    operation.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    assert_equal false, operation.assignments(nil, { }, [ ])
    assert_equal [ :test_field ], operation.assignments(nil, { }, [ :only_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :except_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :only_tag, :except_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :except_tag, :only_tag ])
    assert_equal false, operation.assignments(nil, { }, [ :except_tag, :only_tag, :irrelevant_tag ])
    assert_equal [ :test_field ], operation.assignments(nil, { }, [ :only_tag, :irrelevant_tag ])

    operation.apply!(nil, { }, [ :except_tag ])

    assert_equal 0, triggered

    operation.apply!(nil, { }, [ :except_tag, :only_tag ])

    assert_equal 0, triggered

    operation.apply!(nil, { }, [ :only_tag ])

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
    triggered = 0
    block = lambda { triggered += 1 }
    model = MockModelExample.new(:field => nil)

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :block => block
    )

    operation.apply!(model, { :field => true }, [ ])

    assert_equal 0, triggered

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
    triggered = 0
    block = lambda { triggered += 1 }
    model = MockModelExample.new(:field => :reference)

    assert_equal %w[ field ], model.changed

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :foreign_key => :field_id,
      :block => block
    )

    assert_equal [ :field, 'field', :field_id, 'field_id' ], operation.source_keys
    assert_equal [ :field, :field_id ], operation.source_methods

    assert_equal false, operation.assignments(model, { :field => :reference }, [ ])

    operation.apply!(model, { }, [ ])

    assert_equal 0, triggered

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

    assert_equal %w[ field_id ], model.changed

    assert_equal false, operation.assignments(model, { }, [ ])

    operation.apply!(model, { }, [ ])

    assert_equal false, triggered

    assert_equal 1, model.field_id
  end

  def test_block_with_model_inheritance_as_symbol
    model = MockModelExample.new
    model.root_id = 1

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
    model = MockModelExample.new
    model.root_id = 1

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

  def test_with_reflection_already_assigned
    model = MockModelExample.new(:field_id => 1)

    assert_equal %w[ field_id ], model.changed

    operation = TestDummy::Operation.new(
      :fields => [ :field ],
      :model_class => MockModelExample,
      :foreign_key => :field_id
    )

    assert_equal false, operation.assignments(model, { }, [ ])
  end

  def test_with_model_field_default
    model = MockModelExample.new

    assert_equal 0, model.integer
    assert_equal [ ], model.changed

    triggered = 0

    operation = TestDummy::Operation.new(
      :fields => [ :integer ],
      :block => lambda { triggered += 1 }
    )

    assert_equal 0, triggered

    operation.apply!(model, { }, [ ])

    assert_equal 1, model.integer

    assert_equal 1, triggered
  end

  def test_with_model_accessor_when_not_populated
    model = MockModelExample.new

    triggered = 0

    operation = TestDummy::Operation.new(
      :fields => [ :temporary ],
      :block => lambda { triggered += 1 }
    )

    operation.apply!(model, { }, [ ])

    assert_equal 1, triggered
    assert_equal 1, model.temporary
  end

  def test_with_model_accessor_when_populated
    model = MockModelExample.new
    model.temporary = :temp

    triggered = 0

    operation = TestDummy::Operation.new(
      :fields => [ :temporary ],
      :block => lambda { triggered += 1 }
    )

    operation.apply!(model, { }, [ ])

    assert_equal 0, triggered
    assert_equal :temp, model.temporary
  end
end
