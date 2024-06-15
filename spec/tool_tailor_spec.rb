class TestClass
  # Get the current temperature for a specific location.
  #
  # @param location [String] The city and state, e.g., San Francisco, CA.
  # @param unit [String] The temperature unit to use. Infer this from the user's location.
  # @values unit ["Celsius", "Fahrenheit"]
  def get_current_temperature(location:, unit:)
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
        "name" => "get_current_temperature",
        "description" => "Get the current temperature for a specific location.",
        "parameters" => {
          "type" => "object",
          "properties" => {
            "location" => {
              "type" => "string",
              "description" => "The city and state, e.g., San Francisco, CA."
            },
            "unit" => {
              "type" => "string",
              "description" => "The temperature unit to use. Infer this from the user's location.",
              "enum" => ["Celsius", "Fahrenheit"]
            }
          },
          "required" => ["location", "unit"]
        }
      }
    }.to_json

    # Assert that the generated schema matches the expected schema
    expect(TestClass.instance_method(:get_current_temperature).to_json_schema).to eq(expected_schema)
    expect(TestClass.new.method(:get_current_temperature).to_json_schema).to eq(expected_schema)
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
end
