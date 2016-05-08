# Shrine::Plugins::Reform

Provides [Reform] integration for [Shrine].

## Installation

```ruby
gem "shrine-reform"
gem "shrine", github: "janko-m/shrine"
```

## Usage

The reform plugin can be loaded globally alongside the activerecord plugin.

```rb
Shrine.plugin :activerecord
Shrine.plugin :reform
```
```rb
class Post < ActiveRecord::Base
  include ImageUploader[:image]
end
```
```rb
class PostForm < Reform::Form
  prepend ImageUploader[:image]
end
```

Notice that the only difference from ActiveRecord is that a Reform attachment
module has to be *prepended* instead of included.

## License

[MIT](LICENSE.txt)

[Reform]: https://github.com/apotonick/reform
[Shrine]: https://github.com/janko-m/shrine
