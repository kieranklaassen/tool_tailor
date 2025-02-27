# frozen_string_literal: true

require "tool_tailor/version"
require "tool_tailor/errors"
require "json"
require "yard"
require "yard_custom_tags"
require "logger"

# ToolTailor converts Ruby methods with YARD documentation to OpenAI/Anthropic tool JSON schemas
module ToolTailor
  class << self
    attr_writer :logger

    # Returns the logger instance, creating one if it doesn't exist
    #
    # @return [Logger] The logger instance
    def logger
      @logger ||= begin
        logger = Logger.new($stdout)
        logger.level = Logger::WARN
        logger
      end
    end

    # Enable debug logging
    #
    # @return [void]
    def enable_debug!
      logger.level = Logger::DEBUG
    end

    # Disable debug logging
    #
    # @return [void]
    def disable_debug!
      logger.level = Logger::WARN
    end

    # Converts a method to a JSON schema representation for tool calling APIs.
    #
    # @param method [Method, UnboundMethod] The method to convert
    # @param format [Symbol] The format to return. Either :hash or :json (default)
    # @return [String, Hash] The JSON schema representation of the method
    # @raise [ArgumentError] If the provided object is not a Method or UnboundMethod
    # @raise [ParseError] If YARD fails to parse the method
    #
    # @example
    #   def get_weather(location:, unit:)
    #     # method implementation
    #   end
    #
    #   ToolTailor.convert(method(:get_weather))
    #
    def convert(method, format: :json)
      validate_method_type!(method)
      
      result = convert_method(method)
      format == :json ? result.to_json : result
    end

    # Convert an array of methods to JSON schemas
    #
    # @param methods [Array<Method, UnboundMethod>] The methods to convert
    # @param format [Symbol] The format to return. Either :hash or :json (default)
    # @return [Array<Hash, String>] Array of schema representations
    def batch_convert(methods, format: :hash)
      methods.map { |method| convert(method, format: format) }
    end

    private

    # Validates that the object is a Method or UnboundMethod
    #
    # @param method [Object] The object to validate
    # @raise [ArgumentError] If the object is not a Method or UnboundMethod
    # @return [void]
    def validate_method_type!(method)
      return if method.is_a?(Method) || method.is_a?(UnboundMethod)

      raise ArgumentError, "Unsupported object type: #{method.class}, only Method and UnboundMethod are supported"
    end

    # Validates that the method uses only keyword arguments
    #
    # @param method [Method, UnboundMethod] The method to validate
    # @raise [ArgumentError] If the method uses non-keyword arguments
    # @return [void]
    def validate_named_args!(method)
      return if method.parameters.all? { |type, _| type == :keyreq || type == :key }

      raise ArgumentError, "Only named arguments are supported"
    end

    # Parses YARD documentation for a method
    #
    # @param method [Method, UnboundMethod] The method to parse
    # @return [YARD::CodeObjects::MethodObject, nil] The parsed YARD object or nil if not found
    # @raise [ParseError] If YARD fails to parse the method
    def parse_yard_object(method)
      file_path, = method.source_location
      begin
        YARD.parse(file_path)
      rescue => e
        raise ParseError, "Failed to parse YARD documentation: #{e.message}"
      end

      method_path = "#{method.owner}##{method.name}"
      yard_object = YARD::Registry.at(method_path)
      
      logger.debug { "Converting method: #{method_path}" }
      logger.debug { "Found YARD documentation: #{!yard_object.nil?}" }

      yard_object
    end

    # Converts a method to a JSON schema representation.
    #
    # @param method [Method, UnboundMethod] The method to convert
    # @return [Hash] The schema hash representation of the method
    def convert_method(method)
      validate_named_args!(method)
      yard_object = parse_yard_object(method)
      
      # Extract parameters from the method definition
      parameters = extract_parameters(method)
      method_description = extract_description(yard_object)

      # Process YARD tags if available
      if yard_object
        process_param_tags(yard_object, parameters)
        process_enum_tags(yard_object, parameters)
        process_items_type_tags(yard_object, parameters)
        process_min_items_tags(yard_object, parameters)
        process_max_items_tags(yard_object, parameters)
      end

      build_schema(method.name.to_s, method_description, parameters)
    end

    # Extracts parameters from a method definition
    #
    # @param method [Method, UnboundMethod] The method to extract parameters from
    # @return [Array<Hash>] Array of parameter details
    def extract_parameters(method)
      method.parameters.map do |param_type, name|
        {
          name: name.to_s,
          type: "string",
          description: "",
          enum: nil,
          items: nil,
          min_items: nil,
          max_items: nil,
          required: param_type == :keyreq
        }
      end
    end

    # Extracts the method description from YARD documentation
    #
    # @param yard_object [YARD::CodeObjects::MethodObject, nil] The YARD object
    # @return [String] The method description
    def extract_description(yard_object)
      return "" unless yard_object

      yard_object.docstring.to_s.strip
    end

    # Processes parameter tags from YARD documentation
    #
    # @param yard_object [YARD::CodeObjects::MethodObject] The YARD object
    # @param parameters [Array<Hash>] Array of parameter details to update
    # @return [void]
    def process_param_tags(yard_object, parameters)
      yard_object.tags("param").each do |tag|
        param_name = tag.name.to_s.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        
        next unless param

        logger.debug { "Processing parameter '#{param_name}' with type #{tag.types.inspect}" }
        
        begin
          param[:type] = type_mapping(tag.types.first)
        rescue TypeError => e
          logger.warn { "Invalid type for parameter '#{param_name}': #{e.message}" }
        end
        
        param[:description] = tag.text.to_s.strip
      end
    end

    # Processes enum tags from YARD documentation
    #
    # @param yard_object [YARD::CodeObjects::MethodObject] The YARD object
    # @param parameters [Array<Hash>] Array of parameter details to update
    # @return [void]
    def process_enum_tags(yard_object, parameters)
      yard_object.tags("values").each do |tag|
        param_name = tag.name.to_s.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        
        next unless param

        begin
          enum_values = parse_enum_values(tag)
          
          if enum_values
            param[:enum] = enum_values
            logger.debug { "Added enum values for '#{param_name}': #{enum_values.inspect}" }
          end
        rescue => e
          logger.warn { "Error processing enum values for '#{param_name}': #{e.message}" }
        end
      end
    end
    
    # Processes items_type tags from YARD documentation
    #
    # @param yard_object [YARD::CodeObjects::MethodObject] The YARD object
    # @param parameters [Array<Hash>] Array of parameter details to update
    # @return [void]
    def process_items_type_tags(yard_object, parameters)
      yard_object.tags("items_type").each do |tag|
        param_name = tag.name.to_s.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        
        next unless param
        
        begin
          # Ensure the type is "array" for any parameter with @items_type tag
          if param[:type] != "array"
            logger.debug { "Setting type to array for '#{param_name}' since it has @items_type tag" }
            param[:type] = "array"
          end
          
          # Convert Ruby type to JSON schema type
          items_type = type_mapping(tag.text)
          param[:items] = items_type
          logger.debug { "Added items type for '#{param_name}': #{items_type}" }
        rescue => e
          logger.warn { "Error processing items type for '#{param_name}': #{e.message}" }
        end
      end
    end
    
    # Processes min_items tags from YARD documentation
    #
    # @param yard_object [YARD::CodeObjects::MethodObject] The YARD object
    # @param parameters [Array<Hash>] Array of parameter details to update
    # @return [void]
    def process_min_items_tags(yard_object, parameters)
      yard_object.tags("min_items").each do |tag|
        param_name = tag.name.to_s.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        
        next unless param
        
        begin
          # Ensure the type is "array" for any parameter with @min_items tag
          if param[:type] != "array"
            logger.debug { "Setting type to array for '#{param_name}' since it has @min_items tag" }
            param[:type] = "array"
          end
          
          min_items = tag.text.to_i
          param[:min_items] = min_items
          logger.debug { "Added minItems for '#{param_name}': #{min_items}" }
        rescue => e
          logger.warn { "Error processing minItems for '#{param_name}': #{e.message}" }
        end
      end
    end
    
    # Processes max_items tags from YARD documentation
    #
    # @param yard_object [YARD::CodeObjects::MethodObject] The YARD object
    # @param parameters [Array<Hash>] Array of parameter details to update
    # @return [void]
    def process_max_items_tags(yard_object, parameters)
      yard_object.tags("max_items").each do |tag|
        param_name = tag.name.to_s.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        
        next unless param
        
        begin
          # Ensure the type is "array" for any parameter with @max_items tag
          if param[:type] != "array"
            logger.debug { "Setting type to array for '#{param_name}' since it has @max_items tag" }
            param[:type] = "array"
          end
          
          max_items = tag.text.to_i
          param[:max_items] = max_items
          logger.debug { "Added maxItems for '#{param_name}': #{max_items}" }
        rescue => e
          logger.warn { "Error processing maxItems for '#{param_name}': #{e.message}" }
        end
      end
    end

    # Parses enum values from a YARD tag
    #
    # @param tag [YARD::Tags::Tag] The YARD tag containing enum values
    # @return [Array, nil] The parsed enum values or nil if parsing failed
    def parse_enum_values(tag)
      # Direct array from YARD parser
      return tag.text if tag.text.is_a?(Array)
      
      # Try to parse as JSON
      begin
        return JSON.parse(tag.text)
      rescue JSON::ParserError
        # Simple parsing of the format ["Value1", "Value2"]
        if tag.text =~ /\[.*\]/
          values = tag.text.gsub(/[\[\]\s"']/, '').split(',')
          logger.debug { "Parsed enum values using simple parser: #{values.inspect}" }
          return values
        end
        
        logger.warn { "Invalid format for enum values: #{tag.text}" }
        return nil
      end
    end

    # Builds the final JSON schema
    #
    # @param name [String] The method name
    # @param description [String] The method description
    # @param parameters [Array<Hash>] Array of parameter details
    # @return [Hash] The complete schema
    def build_schema(name, description, parameters)
      {
        type: "function",
        function: {
          name: name,
          description: description,
          parameters: {
            type: "object",
            properties: build_properties(parameters),
            required: parameters.select { |param| param[:required] }
                               .map { |param| param[:name] }
          }
        }
      }
    end

    # Builds the properties object for the schema
    #
    # @param parameters [Array<Hash>] Array of parameter details
    # @return [Hash] The properties object
    def build_properties(parameters)
      parameters.map do |param|
        property = {
          type: param[:type],
          description: param[:description],
          enum: param[:enum]
        }
        
        # Add array-specific properties
        if param[:type] == "array"
          # Add items type if specified
          if param[:items]
            property[:items] = { type: param[:items] }
          end
          
          # Add minItems if specified
          if param[:min_items]
            property[:minItems] = param[:min_items]
          end
          
          # Add maxItems if specified
          if param[:max_items]
            property[:maxItems] = param[:max_items]
          end
        end
        
        [param[:name], property.compact]
      end.to_h
    end

    # Maps Ruby types to JSON schema types.
    #
    # @param type [String] The Ruby type to map
    # @return [String] The corresponding JSON schema type
    # @raise [TypeError] If the provided type is not supported
    def type_mapping(type)
      return "string" if type.nil?
      
      case type
      when "String"    then "string"
      when "Integer"   then "integer"
      when "Float"     then "number"
      when "Numeric"   then "number"
      when "Boolean", "TrueClass", "FalseClass" then "boolean"
      when "Array"     then "array"
      when "Hash"      then "object"
      when "NilClass"  then "null"
      # Allow complex types to be passed through as strings
      else
        logger.debug { "Using 'string' for complex type: #{type}" }
        "string"
      end
    rescue => e
      raise TypeError, "Error mapping type '#{type}': #{e.message}"
    end
  end
end

# Extension for the UnboundMethod class
class UnboundMethod
  # Converts an UnboundMethod to a JSON schema.
  #
  # @param format [Symbol] The format to return. Either :hash or :json (default)
  # @return [String, Hash] The JSON schema representation of the method
  def to_json_schema(format: :json)
    ToolTailor.convert(self, format: format)
  end
end

# Extension for the Method class
class Method
  # Converts a Method to a JSON schema.
  #
  # @param format [Symbol] The format to return. Either :hash or :json (default)
  # @return [String, Hash] The JSON schema representation of the method
  def to_json_schema(format: :json)
    ToolTailor.convert(self, format: format)
  end
end