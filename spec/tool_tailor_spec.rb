class TestClass
  # Get the current weather in a given location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The unit of temperature, either 'celsius' or 'fahrenheit'.
  # @param api_key [Float] The API key for the weather service.
  def get_current_weather(location, unit = 'celsius', api_key: nil)
    # Function implementation goes here
  end

  def self.to_json_schema
    ToolTailor.convert(instance_method(:get_current_weather))
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
          "required" => ["location", "unit", "api_key"]
        }
      }
    }.to_json

    # Assert that the generated schema matches the expected schema
    expect(TestClass.to_json_schema).to eq(expected_schema)
  end
end
