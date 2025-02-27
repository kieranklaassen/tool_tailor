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
  
  # Get a list of tags for a product
  #
  # @param product_id [String] The ID of the product
  # @param include_hidden [Boolean] Whether to include hidden tags
  # @param tags [Array] Tags to filter by
  # @items_type tags String
  def product_tags(product_id:, include_hidden: false, tags: [])
    # Implementation
  end
  
  # Process order items
  #
  # @param order_id [String] The ID of the order
  # @param items [Array] Array of item objects
  # @items_type items Object
  def process_order_items(order_id:, items:)
    # Implementation
  end
  
  # Get the top categories with constraints on array size
  #
  # @param store_id [String] The ID of the store
  # @param categories [Array] List of category IDs to include
  # @items_type categories String
  # @min_items categories 1
  # @max_items categories 5
  def top_categories(store_id:, categories:)
    # Implementation
  end
  
  # Get related products
  #
  # @param product_id [String] The ID of the product
  # @param related_ids [Array] List of related product IDs
  # @items_type related_ids String
  # @min_items related_ids 3
  # @max_items related_ids 10
  def related_products(product_id:, related_ids:)
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
  
  it "supports array items type specification" do
    schema = ToolTailor.convert(TestClass.instance_method(:product_tags), format: :hash)
    
    expect(schema[:function][:parameters][:properties]["tags"][:type]).to eq("array")
    expect(schema[:function][:parameters][:properties]["tags"][:items][:type]).to eq("string")
  end
  
  it "supports complex items type for arrays" do
    schema = ToolTailor.convert(TestClass.instance_method(:process_order_items), format: :hash)
    
    expect(schema[:function][:parameters][:properties]["items"][:type]).to eq("array")
    expect(schema[:function][:parameters][:properties]["items"][:items][:type]).to eq("string")
  end
  
  it "supports minItems and maxItems constraints for arrays" do
    schema = ToolTailor.convert(TestClass.instance_method(:top_categories), format: :hash)
    
    expect(schema[:function][:parameters][:properties]["categories"][:type]).to eq("array")
    expect(schema[:function][:parameters][:properties]["categories"][:items][:type]).to eq("string")
    expect(schema[:function][:parameters][:properties]["categories"][:minItems]).to eq(1)
    expect(schema[:function][:parameters][:properties]["categories"][:maxItems]).to eq(5)
  end
  
  it "correctly combines items_type with min/max constraints" do
    schema = ToolTailor.convert(TestClass.instance_method(:related_products), format: :hash)
    
    array_props = schema[:function][:parameters][:properties]["related_ids"]
    expect(array_props[:type]).to eq("array")
    expect(array_props[:items][:type]).to eq("string")
    expect(array_props[:minItems]).to eq(3)
    expect(array_props[:maxItems]).to eq(10)
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