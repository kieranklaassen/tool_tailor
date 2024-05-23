# ToolTailor

ToolTailor is a Ruby gem that converts methods to OpenAI JSON schemas for use with tools, making it easier to integrate with OpenAI's API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tool_tailor'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tool_tailor

## Usage

```rb
class TestClass
  # Get the current weather in a given location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The unit of temperature, either 'celsius' or 'fahrenheit'.
  # @param api_key [Float] The API key for the weather service.
  def get_current_weather(location, unit = 'celsius', api_key: nil)
    # Function implementation goes here
  end
end

TestClass.to_json_schema(:get_current_weather) # => {
#   "type" => "function",
#   "function" => {
#     "name" => "get_current_weather",
#     "description" => "Get the current weather in a given location.",
#     "parameters" => {
#       "type" => "object",
#       "properties" => {
#         "location" => {
#           "type" => "string",
#           "description" => "The city and state, e.g., San Francisco, CA."
#         },
#         "unit" => {
#           "type" => "string",
#           "description" => "The unit of temperature, either 'celsius' or 'fahrenheit'."
#         },
#         "api_key" => {
#           "type" => "number",
#           "description" => "The API key for the weather service."
#         }
#       },
#       "required" => ["location", "unit", "api_key"]
#     }
#   }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tool_tailor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/tool_tailor/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
