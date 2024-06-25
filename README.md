# ToolTailor

ToolTailor is a Ruby gem that converts methods and classes to OpenAI JSON schemas for use with tools, making it easier to integrate with OpenAI's API.

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

ToolTailor can convert both methods and classes to JSON schemas:

### Converting Methods

```ruby
class WeatherService
  # Get the current weather in a given location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The unit of temperature, either 'celsius' or 'fahrenheit'.
  def get_current_weather(location:, unit: 'celsius')
    # Function implementation goes here
  end
end

# Convert an instance method
schema = ToolTailor.convert(WeatherService.instance_method(:get_current_weather))

# Using to_json_schema on an unbound method
schema = WeatherService.instance_method(:get_current_weather).to_json_schema

# Using to_json_schema on a bound method
weather_service = WeatherService.new
schema = weather_service.method(:get_current_weather).to_json_schema
```

### Converting Classes

When passing a class, ToolTailor assumes you want to use the `new` method and generates the schema based on the `initialize` method:

```ruby
class User
  # Create a new user
  #
  # @param name [String] The user's name
  # @param age [Integer] The user's age
  def initialize(name:, age:)
    @name = name
    @age = age
  end
end

# Convert a class
schema = ToolTailor.convert(User)

# or
schema = User.to_json_schema

# This is equivalent to:
schema = ToolTailor.convert(User.instance_method(:initialize))
```

The resulting schema will look like this:

```ruby
{
  "type" => "function",
  "function" => {
    "name" => "User",
    "description" => "Create a new user",
    "parameters" => {
      "type" => "object",
      "properties" => {
        "name" => {
          "type" => "string",
          "description" => "The user's name"
        },
        "age" => {
          "type" => "integer",
          "description" => "The user's age"
        }
      },
      "required" => ["name", "age"]
    }
  }
}
```

### Using with ruby-openai

Here's an example of how to use ToolTailor with the [ruby-openai](https://github.com/alexrudall/ruby-openai) gem:

```ruby
response = client.chat(
  parameters: {
    model: "gpt-4",
    messages: [
      { role: "user", content: "Create a user named Alice who is 30 years old" }
    ],
    tools: [ToolTailor.convert(User)],
    tool_choice: { type: "function", function: { name: "User" } }
  }
)

message = response.dig("choices", 0, "message")

if message["role"] == "assistant" && message["tool_calls"]
  function_name = message.dig("tool_calls", 0, "function", "name")
  args = JSON.parse(
    message.dig("tool_calls", 0, "function", "arguments"),
    { symbolize_names: true }
  )

  case function_name
  when "User"
    user = User.new(**args)
    puts "Created user: #{user.name}, age #{user.age}"
  end
end
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
