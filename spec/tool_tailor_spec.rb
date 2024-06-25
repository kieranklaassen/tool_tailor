# Class with YARD documentation
class TestClass
  # @param name [String] The name of the test instance
  # @param value [Integer] A test value
  # @param options [Hash] Additional options
  def initialize(name: "default", value: 1, options: {})
    @name = name
    @value = value
    @options = options
  end

  # Get the current weather in a given location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The unit of temperature, either 'celsius' or 'fahrenheit'.
  # @param api_key: [Float] The API key for the weather service.
  def get_current_weather(location:, unit: 'celsius', api_key: nil)
    # Function implementation goes here
  end

  def missing_yard(text:)
  end

  def not_named_arg(text)
  end
end

RSpec.describe ToolTailor do
  it "has a version number" do
    expect(ToolTailor::VERSION).not_to be nil
  end

  it "converts a function to a JSON schema representation using YARD" do
    # Expected JSON schema structure
    expected_schema = {
      "type" => "function",
      "function" => {
        "name" => "get_current_weather",
        "description" => "Get the current weather in a given location.",
        "parameters" => {
          "type" => "object",
          "properties" => {
            "location" => {
              "type" => "string",
              "description" => "The city and state, e.g., San Francisco, CA."
            },
            "unit" => {
              "type" => "string",
              "description" => "The unit of temperature, either 'celsius' or 'fahrenheit'."
            },
            "api_key" => {
              "type" => "number",
              "description" => "The API key for the weather service."
            }
          },
          "required" => ["location"]
        }
      }
    }.to_json

    # Assert that the generated schema matches the expected schema
    expect(TestClass.instance_method(:get_current_weather).to_json_schema).to eq(expected_schema)
    expect(TestClass.new.method(:get_current_weather).to_json_schema).to eq(expected_schema)
  end

  it "handles missing YARD documentation gracefully" do
    expected_schema = {
      "type" => "function",
      "function" => {
        "name" => "missing_yard",
        "description" => "",
        "parameters" => {
          "type" => "object",
          "properties" => {
            "text" => {
              "type" => "string",
              "description" => ""
            }
          },
          "required" => ["text"]
        }
      }
    }.to_json

    expect(TestClass.instance_method(:missing_yard).to_json_schema).to eq(expected_schema)
    expect(TestClass.new.method(:missing_yard).to_json_schema).to eq(expected_schema)
  end

  it "raises an error for non-named arguments" do
    expect {
      TestClass.instance_method(:not_named_arg).to_json_schema
    }.to raise_error(ArgumentError, /Only named arguments are supported/)
  end

  it "converts a class to a JSON schema representation using the initialize method" do
    expected_schema = {
      "type" => "function",
      "function" => {
        "name" => "TestClass",
        "description" => "Class with YARD documentation",
        "parameters" => {
          "type" => "object",
          "properties" => {
            "name" => {
              "type" => "string",
              "description" => "The name of the test instance"
            },
            "value" => {
              "type" => "integer",
              "description" => "A test value"
            },
            "options" => {
              "type" => "object",
              "description" => "Additional options"
            }
          },
          "required" => []
        }
      }
    }.to_json

    expect(ToolTailor.convert(TestClass)).to eq(expected_schema)
  end
end
