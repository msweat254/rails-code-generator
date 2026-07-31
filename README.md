# rails-code-generator

Custom Rails generators for scaffolding and code generation in Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails-code-generator", git: "https://github.com/msweat254/rails-code-generator.git"
```

Or install directly from GitHub:

```bash
gem install rails-code-generator --source https://rubygems.org
```

Once published to RubyGems.org:

```bash
bundle add rails-code-generator
```

## Usage

Generators are invoked from within a Rails application.

### `rails_code_generator:resources`

Generates a full resource stack (controller, services, validators, and request specs) from Ion Solar backend conventions.

```bash
bin/rails generate rails_code_generator:resources PricingConfig
bin/rails generate rails_code_generator:resources PricingConfig --bulk
```

**Options**

| Flag | Default | Description |
|------|---------|-------------|
| `--bulk` | `false` | Generate bulk create/update/destroy patterns |

**Generated files** (for `PricingConfig`):

| Path | Single | Bulk |
|------|--------|------|
| `app/controllers/pricing_configs_controller.rb` | yes | yes |
| `app/services/pricing_configs/build.rb` | yes | yes |
| `app/services/pricing_configs/save.rb` | yes | yes |
| `app/services/pricing_configs/update.rb` | yes | yes |
| `app/validators/pricing_configs/create_validator.rb` | yes | yes |
| `app/validators/pricing_configs/update_validator.rb` | yes | yes |
| `spec/requests/pricing_configs/index_spec.rb` | yes | yes |
| `spec/requests/pricing_configs/show_spec.rb` | yes | yes |
| `spec/requests/pricing_configs/create_spec.rb` | yes | yes |
| `spec/requests/pricing_configs/update_spec.rb` | yes | yes |
| `spec/requests/pricing_configs/destroy_spec.rb` | yes | yes |

**Bulk vs single differences**

- Controller, services, and validators use single or bulk snippet patterns
- Request specs: bulk create/update use `pricing_configs: {}` param key (plural); bulk destroy passes `params: { ids: ids }` instead of an id in the path
- `PERMITTED_ATTRIBUTES` and validator fields are generated as stubs — fill them in after running the generator

Other generators:

```bash
bin/rails generate rails_code_generator:<generator_name>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Generator structure

Generators live under `lib/generators/rails_code_generator/`. Each generator follows the standard Rails generator layout:

```
lib/generators/rails_code_generator/
  my_thing/
    my_thing_generator.rb
    templates/
      ...
```

Invoked as `bin/rails generate rails_code_generator:my_thing`.

## Contributing

Bug reports and pull requests are welcome on GitHub at [msweat254/rails-code-generator](https://github.com/msweat254/rails-code-generator).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
