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
  # @param unit [String] The temperature unit to use. Infer this from the user's location.
  # @values unit ["Celsius", "Fahrenheit"]
  def get_current_temperature(location:, unit:)
    # Function implementation goes here
  end

  def missing_yard(text:)
  end

  def not_named_arg(text)
  end
  
  # Search for products in the catalog.
  #
  # @param query [String] The search query term
  # @param category [String] Product category to filter by
  # @param max_price [Float] Maximum price filter
  # @param sort_by [String] Field to sort results by
  # @values sort_by ["price_asc", "price_desc", "newest", "best_match"]
  # @param limit [Integer] Maximum number of results to return (1-100)
  def search_products(query:, category: nil, max_price: nil, sort_by: "best_match", limit: 20)
    # Implementation
  end
  
  # Get available shipping options
  #
  # @param destination [Hash] Shipping destination address
  # @param weight [Float] Package weight in kg
  # @param dimensions [Hash] Package dimensions in cm
  # @param express_only [Boolean] Only show express shipping options
  def shipping_options(destination:, weight:, dimensions: nil, express_only: false)
    # Implementation
  end
end

RSpec.describe ToolTailor do
  before do
    # Redirect logger output during tests
    ToolTailor.logger = Logger.new(StringIO.new)
  end
  
  it "has a version number" do
    expect(ToolTailor::VERSION).not_to be nil
  end

  it "converts a function to a JSON schema representation using YARD" do
    # Expected JSON schema structure
    expected_schema = {
      "type" => "function",
      "function" => {
        "name" => "get_current_temperature",
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

  it "raises an error for classes" do
    expect {
      ToolTailor.convert(TestClass)
    }.to raise_error(ArgumentError, /only Method and UnboundMethod are supported/)
  end
  
  it "correctly handles optional parameters" do
    schema = ToolTailor.convert(TestClass.instance_method(:search_products), format: :hash)
    
    expect(schema[:function][:name]).to eq("search_products")
    expect(schema[:function][:parameters][:required]).to eq(["query"])
    expect(schema[:function][:parameters][:properties].keys).to include("query", "category", "max_price", "sort_by", "limit")
    expect(schema[:function][:parameters][:properties]["sort_by"][:enum]).to eq(["price_asc", "price_desc", "newest", "best_match"])
    expect(schema[:function][:parameters][:properties]["limit"][:type]).to eq("integer")
  end
  
  it "handles complex parameter types" do
    schema = ToolTailor.convert(TestClass.instance_method(:shipping_options), format: :hash)
    
    expect(schema[:function][:parameters][:properties]["destination"][:type]).to eq("object")
    expect(schema[:function][:parameters][:properties]["weight"][:type]).to eq("number")
    expect(schema[:function][:parameters][:properties]["express_only"][:type]).to eq("boolean")
  end
  
  it "supports batch conversion of multiple methods" do
    methods = [
      TestClass.instance_method(:get_current_temperature),
      TestClass.instance_method(:search_products)
    ]
    
    schemas = ToolTailor.batch_convert(methods)
    expect(schemas).to be_an(Array)
    expect(schemas.size).to eq(2)
    expect(schemas[0][:function][:name]).to eq("get_current_temperature")
    expect(schemas[1][:function][:name]).to eq("search_products")
  end
  
  it "returns hash format when specified" do
    schema = TestClass.instance_method(:get_current_temperature).to_json_schema(format: :hash)
    expect(schema).to be_a(Hash)
    expect(schema[:function][:name]).to eq("get_current_temperature")
  end
end