require "tool_tailor/version"
require "json"
require "yard"
require "yard_custom_tags"
require "logger"

module ToolTailor
  class Error < StandardError; end
  class TypeError < StandardError; end
  class ParseError < StandardError; end

  class << self
    attr_accessor :logger

    # @return [Logger] The logger instance.
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
    # @param method [Method, UnboundMethod] The method to convert.
    # @param format [Symbol] The format to return. Either :hash or :json (default).
    # @return [String, Hash] The JSON schema representation of the method.
    # @raise [ArgumentError] If the provided object is not a Method or UnboundMethod.
    # @raise [ParseError] If YARD fails to parse the method.
    #
    # @example
    #   def get_weather(location:, unit:)
    #     # method implementation
    #   end
    #
    #   ToolTailor.convert(method(:get_weather))
    #
    def convert(method, format: :json)
      unless method.is_a?(Method) || method.is_a?(UnboundMethod)
        raise ArgumentError, "Unsupported object type: #{method.class}, only Method and UnboundMethod are supported"
      end
      
      result = convert_method(method)
      format == :json ? result.to_json : result
    end

    # Converts a method to a JSON schema representation.
    #
    # @param method [Method, UnboundMethod] The method to convert.
    # @return [Hash] The schema hash representation of the method.
    # @api private
    def convert_method(method)
      # Ensure only named arguments are allowed
      unless method.parameters.all? { |type, _| type == :keyreq || type == :key }
        raise ArgumentError, "Only named arguments are supported"
      end

      file_path, line_number = method.source_location
      begin
        YARD.parse(file_path)
      rescue => e
        raise ParseError, "Failed to parse YARD documentation: #{e.message}"
      end

      method_path = "#{method.owner}##{method.name}"
      yard_object = YARD::Registry.at(method_path)
      
      logger.debug "Converting method: #{method_path}"
      
      # Extract parameters from the method definition
      parameters = method.parameters.map do |param_type, name|
        {
          name: name.to_s,
          type: "string",
          description: "",
          enum: nil,
          required: param_type == :keyreq
        }
      end

      method_description = ""

      if yard_object
        logger.debug "Found YARD documentation for #{method_path}"
        method_description = yard_object.docstring.to_s.strip

        # Process parameter tags
        yard_object.tags("param").each do |tag|
          param_name = tag.name.to_s.chomp(':')
          param = parameters.find { |p| p[:name] == param_name }
          
          if param
            logger.debug "Processing parameter '#{param_name}' with type #{tag.types.inspect}"
            
            begin
              param[:type] = type_mapping(tag.types.first)
            rescue TypeError => e
              logger.warn "Invalid type for parameter '#{param_name}': #{e.message}"
              # Keep default string type
            end
            
            param[:description] = tag.text.to_s.strip
          else
            logger.warn "Parameter '#{param_name}' documented but not found in method signature"
          end
        end

        # Process values tags for enum parameters
        yard_object.tags("values").each do |tag|
          param_name = tag.name.to_s.chomp(':')
          param = parameters.find { |p| p[:name] == param_name }
          
          if param
            begin
              # The values in the tag may be directly an array from YARD parser
              if tag.text.is_a?(Array)
                enum_values = tag.text
              else
                # Try to parse as JSON, but fall back to simpler parsing if that fails
                begin
                  enum_values = JSON.parse(tag.text)
                rescue JSON::ParserError
                  # Simple parsing of the format ["Value1", "Value2"]
                  if tag.text =~ /\[.*\]/
                    enum_values = tag.text.gsub(/[\[\]\s"']/, '').split(',')
                  else
                    logger.warn "Invalid format for enum values for '#{param_name}': #{tag.text}"
                    enum_values = nil
                  end
                end
              end
              
              param[:enum] = enum_values if enum_values
              logger.debug "Added enum values for '#{param_name}': #{enum_values.inspect}"
            rescue => e
              logger.warn "Error processing enum values for '#{param_name}': #{e.message}"
            end
          else
            logger.warn "Enum values for '#{param_name}' documented but parameter not found in method signature"
          end
        end
      else
        logger.warn "No YARD documentation found for #{method_path}"
      end

      # Build the schema
      {
        type: "function",
        function: {
          name: method.name.to_s,
          description: method_description,
          parameters: {
            type: "object",
            properties: parameters.map do |param|
              [
                param[:name],
                {
                  type: param[:type],
                  description: param[:description],
                  enum: param[:enum]
                }.compact
              ]
            end.to_h,
            required: parameters.select { |param| param[:required] }.map { |param| param[:name] }
          }
        }
      }
    end

    # Maps Ruby types to JSON schema types.
    #
    # @param type [String] The Ruby type to map.
    # @return [String] The corresponding JSON schema type.
    # @raise [TypeError] If the provided type is not supported.
    # @api private
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
        logger.debug "Using 'string' for complex type: #{type}"
        "string"
      end
    rescue => e
      raise TypeError, "Error mapping type '#{type}': #{e.message}"
    end

    # Convert an array of methods to JSON schemas
    #
    # @param methods [Array<Method, UnboundMethod>] The methods to convert
    # @return [Array<Hash>] Array of schema representations
    def batch_convert(methods)
      methods.map { |method| convert(method, format: :hash) }
    end
  end
end

class UnboundMethod
  # Converts an UnboundMethod to a JSON schema.
  #
  # @param format [Symbol] The format to return. Either :hash or :json (default).
  # @return [String, Hash] The JSON schema representation of the method.
  def to_json_schema(format: :json)
    ToolTailor.convert(self, format: format)
  end
end

class Method
  # Converts a Method to a JSON schema.
  #
  # @param format [Symbol] The format to return. Either :hash or :json (default).
  # @return [String, Hash] The JSON schema representation of the method.
  def to_json_schema(format: :json)
    ToolTailor.convert(self, format: format)
  end
end