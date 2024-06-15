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
  # Get the current temperature for a specific location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The temperature unit to use. Infer this from the user's location.
  # @values unit ["Celsius", "Fahrenheit"]
  def get_current_temperature(location:, unit:)
    # Function implementation goes here
  end
end

# Simple
ToolTailor.convert(TestClass.instance_method(:get_current_weather))

# Unbound method with to_json_schema
TestClass.instance_method(:get_current_weather).to_json_schema # => {
#   "type" => "function",
#   "function" => {
#     "name" => "get_current_temperature",
#     "description" => "Get the current temperature for a specific location.",
#     "parameters" => {
#       "type" => "object",
#       "properties" => {
#         "location" => {
#           "type" => "string",
#           "description" => "The city and state, e.g., San Francisco, CA."
#         },
#         "unit" => {
#           "type" => "string",
#           "description" => "The temperature unit to use. Infer this from the user's location.",
#           "enum" => ["Celsius", "Fahrenheit"]
#         }
#       },
#       "required" => ["location", "unit"]
#     }
#   }

# Bound method with to_json_schema
example_instance = TestClass.new
example_instance.method(:get_current_weather).to_json_schema # => {
#   "type" => "function",
#   "function" => {
#     "name" => "get_current_temperature",
#     "description" => "Get the current temperature for a specific location.",
#     "parameters" => {
#       "type" => "object",
#       "properties" => {
#         "location" => {
#           "type" => "string",
#           "description" => "The city and state, e.g., San Francisco, CA."
#         },
#         "unit" => {
#           "type" => "string",
#           "description" => "The temperature unit to use. Infer this from the user's location.",
#           "enum" => ["Celsius", "Fahrenheit"]
#         }
#       },
#       "required" => ["location", "unit"]
#     }
#   }
```

And with [ruby-openai](https://github.com/alexrudall/ruby-openai):

```rb
response =
  client.chat(
    parameters: {
      model: "gpt-4o",
      messages: [
        {
          "role": "user",
          "content": "What is the weather like in San Francisco?",
        },
      ],
      tools: [
        TestClass.instance_method(:get_current_temperature).to_json_schema
      ],
      tool_choice: {
        type: "function",
        function: {
          name: "get_current_temperature"
        }
      }
    },
  )

message = response.dig("choices", 0, "message")

if message["role"] == "assistant" && message["tool_calls"]
  function_name = message.dig("tool_calls", 0, "function", "name")
  args =
    JSON.parse(
      message.dig("tool_calls", 0, "function", "arguments"),
      { symbolize_names: true },
    )

  case function_name
  when "get_current_temperature"
    TestClass.get_current_temperature(**args)
  end
end
# => "The weather is nice 🌞"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kieranklaassen/tool_tailor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kieranklaassen/tool_tailor/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
