# ARTransmogrifier

Transforms an ActiveRecord schema.rb file into a set of Ecto models with the appropriate
schema.

## Usage
- Git clone
- `mix deps.get`
```
mix transmogrify MyAppModule /path/to/schema.rb /path/to/output
```

This will transform columns of the form

`foo_id` to `belongs_to :foo, MyAppModule.Foo` and create corresponding
has_many fields. It does not handle polymorphic associations.

## Note

This was created for my own benefit, although it ought to be generally usable.
I will not be answering pull requests or bug reports. Feel free to fork if you want
changes.
