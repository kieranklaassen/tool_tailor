# ToolTailor

ToolTailor is a focused Ruby gem that converts Ruby methods into JSON schemas for OpenAI and Anthropic tool calling APIs.

## Philosophy

ToolTailor is designed as a lightweight building block, not a full framework. It has a single purpose: to convert your existing Ruby methods with YARD documentation into tool schemas for AI tool calling. It doesn't implement the actual API calls or handle responses - it's the glue that helps you expose your existing code to AI systems with minimal effort.

Key principles:
- **Do one thing well**: Convert methods to JSON schemas
- **Leverage existing code**: Use YARD documentation you already have
- **Minimal dependencies**: Just YARD and standard libraries
- **Composable**: Works with any API client of your choice
- **Extensible tags**: Custom YARD tags for array items, enums, and more

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

ToolTailor converts Ruby methods to JSON schemas:

### Converting Methods

```ruby
class WeatherService
  # Get the current weather in a given location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The temperature unit to use. Infer this from the user's location.
  # @values unit ["Celsius", "Fahrenheit"]
  # @param historical_data [Array] Optional array of previous weather readings
  # @items_type historical_data Object
  # @min_items historical_data 1
  # @max_items historical_data 5
  def get_current_temperature(location:, unit:, historical_data: nil)
    # Function implementation goes here
  end
end

# Convert an instance method
schema = ToolTailor.convert(WeatherService.instance_method(:get_current_temperature))

# Using to_json_schema on an unbound method
schema = WeatherService.instance_method(:get_current_temperature).to_json_schema

# Using to_json_schema on a bound method
weather_service = WeatherService.new
schema = weather_service.method(:get_current_temperature).to_json_schema

# Get as a Ruby hash instead of JSON string
schema_hash = weather_service.method(:get_current_temperature).to_json_schema(format: :hash)

# Convert multiple methods at once
methods = [
  WeatherService.instance_method(:get_current_temperature),
  SearchService.instance_method(:search_products)
]
schemas = ToolTailor.batch_convert(methods)
```

The resulting schema will look like this:

```json
{
  "type": "function",
  "function": {
    "name": "get_current_temperature",
    "description": "Get the current weather in a given location.",
    "parameters": {
      "type": "object",
      "properties": {
        "location": {
          "type": "string",
          "description": "The city and state, e.g., San Francisco, CA."
        },
        "unit": {
          "type": "string",
          "description": "The temperature unit to use. Infer this from the user's location.",
          "enum": ["Celsius", "Fahrenheit"]
        },
        "historical_data": {
          "type": "array",
          "description": "Optional array of previous weather readings",
          "items": {
            "type": "object"
          },
          "minItems": 1,
          "maxItems": 5
        }
      },
      "required": ["location", "unit"]
    }
  }
}
```

### Custom YARD Tags

ToolTailor adds support for custom YARD tags to enhance JSON schema generation. Currently, we do not support nested objects with complex properties, but we plan to add this in the future.

#### @values

The `@values` tag specifies allowed values for a parameter (enum in JSON Schema):

```ruby
# @param sort_by [String] Field to sort results by
# @values sort_by ["price_asc", "price_desc", "newest", "best_match"]
```

#### @items_type

The `@items_type` tag specifies the type of items in an array parameter:

```ruby
# @param tags [Array] Array of tag strings
# @items_type tags String

# @param products [Array] Array of product objects
# @items_type products Object
```

#### @min_items and @max_items

The `@min_items` and `@max_items` tags specify the minimum and maximum number of items allowed in an array:

```ruby
# @param categories [Array] List of category IDs to include
# @items_type categories String
# @min_items categories 1
# @max_items categories 5
```

This generates a schema with:

```json
"categories": {
  "type": "array",
  "items": { "type": "string" },
  "minItems": 1,
  "maxItems": 5
}
```

### Debugging and Logging

ToolTailor provides logging capabilities to help debug schema generation:

```ruby
# Enable debug logging
ToolTailor.enable_debug!

# Disable debug logging
ToolTailor.disable_debug!

# Use a custom logger
custom_logger = Logger.new('tool_tailor.log')
custom_logger.level = Logger::INFO
ToolTailor.logger = custom_logger
```

### Using with ruby-openai

Here's an example of how to use ToolTailor with the [ruby-openai](https://github.com/alexrudall/ruby-openai) gem:

```ruby
class WeatherService
  # Get the current weather in a given location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The temperature unit to use. Infer this from the user's location.
  # @values unit ["Celsius", "Fahrenheit"]
  def get_current_weather(location:, unit:)
    # Implementation that fetches real weather data
    { temp: 72, conditions: "Sunny", location: location, unit: unit }
  end
end

weather_service = WeatherService.new
weather_method = weather_service.method(:get_current_weather)

client = OpenAI::Client.new

response = client.chat(
  parameters: {
    model: "gpt-4",
    messages: [
      { role: "user", content: "What's the weather like in San Francisco?" }
    ],
    tools: [ToolTailor.convert(weather_method, format: :hash)],
    tool_choice: "auto"
  }
)

if response.dig("choices", 0, "message", "tool_calls")
  tool_call = response.dig("choices", 0, "message", "tool_calls", 0)
  function_name = tool_call.dig("function", "name")
  arguments = JSON.parse(tool_call.dig("function", "arguments"), symbolize_names: true)
  
  if function_name == "get_current_weather"
    result = weather_service.get_current_weather(**arguments)
    puts "Weather in #{result[:location]}: #{result[:temp]}° #{result[:unit]}, #{result[:conditions]}"
  end
end
```

### Using with anthropic

Similar approach works with the Anthropic Claude API:

```ruby
require 'anthropic'
require 'tool_tailor'

class TranslationService
  # Translate text to another language
  #
  # @param text [String] The text to translate
  # @param target_language [String] The language to translate to
  # @values target_language ["Spanish", "French", "German", "Japanese", "Chinese"]
  def translate(text:, target_language:)
    # Implementation that calls a translation API
    "Translated text in #{target_language}"
  end
end

translation_service = TranslationService.new
translate_method = translation_service.method(:translate)

client = Anthropic::Client.new

response = client.messages(
  model: "claude-3-opus-20240229",
  max_tokens: 1024,
  messages: [
    { role: "user", content: "Can you translate 'Hello world' to French?" }
  ],
  tools: [ToolTailor.convert(translate_method, format: :hash)]
)

# Process tool calls from response
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kieranklaassen/tool_tailor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kieranklaassen/tool_tailor/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ToolTailor project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kieranklaassen/tool_tailor/blob/master/CODE_OF_CONDUCT.md).