# test_dummy

Test Dummy is an easy fake data generator library with the ability to create
individual fake models or complex, inter-linked sets of models on-demand.

ActiveRecord models, the default for Ruby on Rails, is the only type supported
at this time.

The generators produced by Test Dummy can simplify automated testing by making
it possible to have test records created in a known-good state every time
instead of depending on fixture files which may contain irregularities.

After installing the gem, methods to declare how to fake data are made
available within ActiveRecord-derived models. There are several ways to
declare how to dummy something.

## Getting Started

### Add Gem Dependency

To add Test Dummy functionality to an application, add the dependency to the
`Gemfile`:

```ruby
gem 'test_dummy'
```

Most application frameworks provide some kind of test helper foundation,
like `test/test_helper.rb` in Rails or `test/helper.rb` in many gem templates.

Include the following line in there at an appropriate location:

```ruby
require 'test_dummy'
```

This is usually inserted after all the foundational dependencies are taken
care of, so typically later in the file.

### Dummy Attributes

If a model has no validation requirements, it will already have some basic
dummy functionality. Models can be created simply:

```ruby
dummy_example = ExampleModel.create_dummy
```

Like the default `create` method, `create_dummy` also takes arguments that
can be used to supply pre-defined attributes:

```ruby
named_example = ExampleModel.create_dummy(name: 'Example')
```

Any attribute which has validation requirements will need to have a generator
or the models emitted by `create_dummy` cannot be saved. In this example,
if `name` was a required field, this would have to be populated by TestDummy.

For convenience, you can add this directly to the model in question:

```ruby
class ExampleModel < ActiveRecord::Base
  dummy :name do
    'Test Name'
  end
end
```

The `dummy` definition defines an operation that will occur if the attribute
name is not specified. In this case, if `name` is not supplied as an argument
to `create_dummy` then it will be filled in. These operations are attempted in
the order they are defined.

Keep in mind it is possible to create invalid model instances if the parameters
sent in would result in a validation error. For instance:

```ruby
broken_example = ExampleModel.create_dummy(name: nil)

broken_example.valid?
# => false
```

The `dummy` function can be used in several ways to handle a variety of
situations. The default usage is simple:

```ruby
dummy :name do
  'Fake Name'
end
```

In this case, whatever is returned by the block is inserted into the listed
attribute if that attribute was not speficied in the options.

It is possible to dummy several attributes at the same time:

```ruby
dummy :password, :password_confirmation do
  'testpassword'
end
```
This will be applied to any of the listed attributes that have not been
specified in the options.

If access to the model that's being constructed is required, it is passed in
as the first argument to the block:

```ruby
dummy :description do |example|
  "Example with a name of length %d" % example.name.length
end
```
The model itself can be manipulated in any way that's required, such as setting
other fields, calling methods, and so forth, but it's important to be careful
here as the model at this point is incomplete if there are other attributes
which have yet to have had their `dummy` generator called.

### Separate Definition File

If including the attribute dummy generators in the main model file produces
too much clutter, they can be relocated to an alternate location. This has the
advantage in that they will only be loaded if a dummy operation is performed,
so a production application will not be affected by their presence.

An example model `app/models/example_model.rb` file looks like:

```ruby
class ExampleModel < ActiveRecord::Base
  dummy :name do
    "Random Name \#%d" % rand(10e6)
  end
  
  dummy :password, :password_confirmation do
    'tester'
  end
  
  dummy :nickname, use: :random_phonetic_string
end
```

To avoid cluttering up your models with lots of dummy-related code, this can
be stored in the `test/dummy` directory as a secondary file that's loaded as
required.

An example `test/dummy/example_model.rb` looks like this:

```ruby
class ExampleModel
  dummy :name do
    "Random Name \#%d" % rand(10e6)
  end

  dummy :password, :password_confirmation do
    'tester'
  end

  dummy :nickname, use: :random_phonetic_string
end
```

Note that, like any patch to an existing class, it is not strictly required to
re-declare the parent class.

The name of the test/dummy file should be the same as the main model
defined in app/models. For instance, app/models/my_model.rb would have a
corresponding test/dummy/my_model.rb which is loaded on demand.

## Development and Testing

For simplicity and portability, SQLite3 is used as the database back-end for
testing. If any changes are made to existing migrations the temporary database
will need to be deleted before they're applied.

## Copyright

Copyright (c) 2010-2018 Scott Tadman, PostageApp
