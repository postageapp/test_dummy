# test_dummy

Test Dummy is an easy fake data generator library with the ability to create
fake models or entirely faked data structures on-demand.

After installing the gem, methods to declare how to fake data are made
available within ActiveRecord-derived models. There are several ways to
declare how to dummy something.

## Examples

An example model `app/models/my_model.rb` file looks like:

```ruby
class MyModel < ActiveRecord::Base
  # Pass a block that defines how to dummy this attribute
  dummy :name do
    "user%d" % rand(10e6)
  end
  
  # Pass a block that defines how to dummy several attributes
  dummy :password, :password_confirmation do
    'tester'
  end
  
  # Use one of the pre-defined helper methods to dummy this attribute
  dummy :nickname, :use => :random_phonetic_string
end
```

To avoid cluttering up your models with lots of dummy-related code, this can
be stored in the test/dummy directory as a secondary file that's loaded as
required.

An example `test/dummy/my_model.rb` looks like this:

```ruby
class MyModel
  dummy :name do
    "user%d" % rand(10e6)
  end

  dummy :password, :password_confirmation do
    'tester'
  end

  dummy :nickname, :use => :random_phonetic_string
end
```

Note that, like any patch to an existing class, it is not strictly required to
re-declare the parent class.

The name of the test/dummy file should be the same as the main model
defined in app/models. For instance, app/models/my_model.rb would have a
corresponding test/dummy/my_model.rb which is loaded on demand.

## Copyright

Copyright (c) 2010-2013 Scott Tadman, The Working Group Inc.
