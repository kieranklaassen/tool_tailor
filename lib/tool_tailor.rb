require "tool_tailor/version"
require "json"
require "yard"
require "yard_custom_tags"

module ToolTailor
  class Error < StandardError; end

  # Converts a function or class to a JSON schema representation.
  #
  # @param object [Method, UnboundMethod, Class] The function or class to convert.
  # @return [String] The JSON schema representation of the function or class.
  # @raise [ArgumentError] If the provided object is not a Method, UnboundMethod, or Class.
  #
  # @example
  #   def example_method(param1:, param2:)
  #     # method implementation
  #   end
  #
  #   ToolTailor.convert(method(:example_method))
  #
  # @example
  #   class ExampleClass
  #     def initialize(param1:, param2:)
  #       # initialization
  #     end
  #   end
  #
  #   ToolTailor.convert(ExampleClass)
  def self.convert(object)
    case object
    when Method, UnboundMethod
      convert_method(object)
    when Class
      convert_class(object)
    else
      raise ArgumentError, "Unsupported object type: #{object.class}"
    end
  end

  # Converts a method to a JSON schema representation.
  #
  # @param method [Method, UnboundMethod] The method to convert.
  # @return [String] The JSON schema representation of the method.
  def self.convert_method(method)
    # Ensure only named arguments are allowed
    unless method.parameters.all? { |type, _| type == :keyreq || type == :key }
      raise ArgumentError, "Only named arguments are supported"
    end

    file_path, line_number = method.source_location
    YARD.parse(file_path)

    method_path = "#{method.owner}##{method.name}"
    yard_object = YARD::Registry.at(method_path)

    # Extract parameters from the method definition
    parameters = method.parameters.map do |_, name|
      {
        name: name.to_s,
        type: "string",
        description: "",
        enum: nil
      }
    end

    method_description = ""

    if yard_object
      method_description = yard_object.docstring

      yard_object.tags("param").each do |tag|
        param_name = tag.name.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        if param
          param[:type] = type_mapping(tag.types.first)
          param[:description] = tag.text
        end
      end

      yard_object.tags("values").each do |tag|
        param_name = tag.name.chomp(':')
        param = parameters.find { |p| p[:name] == param_name }
        param[:enum] = tag.text if param
      end
    end

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
          required: method.parameters.select { |type, _| type == :keyreq }.map { |_, name| name.to_s }
        }
      }
    }.to_json
  end

  def self.convert_class(klass)
    initialize_method = klass.instance_method(:initialize)
    schema = JSON.parse(convert_method(initialize_method))
    schema["function"]["name"] = klass.name

    # Re-parse YARD documentation for the class
    file_path, _ = initialize_method.source_location
    YARD.parse(file_path)
    class_object = YARD::Registry.at(klass.name)

    if class_object
      schema["function"]["description"] = class_object.docstring.to_s
    end

    schema.to_json
  end

  # Maps Ruby types to JSON schema types.
  #
  # @param type [String] The Ruby type to map.
  # @return [String] The corresponding JSON schema type.
  # @raise [ArgumentError] If the provided type is not supported.
  def self.type_mapping(type)
    case type
    when "String"    then "string"
    when "Integer"   then "integer"
    when "Float"     then "number"
    when "TrueClass", "FalseClass" then "boolean"
    when "Array"     then "array"
    when "Hash"      then "object"
    when "NilClass"  then "null"
    else
      raise ArgumentError, "Unsupported type: #{type} #{type.class}"
    end
  end
end

class UnboundMethod
  # Converts an UnboundMethod to a JSON schema.
  #
  # @return [String] The JSON schema representation of the method.
  def to_json_schema
    ToolTailor.convert(self)
  end
end

class Method
  # Converts a Method to a JSON schema.
  #
  # @return [String] The JSON schema representation of the method.
  def to_json_schema
    ToolTailor.convert(self)
  end
end

class Class
  # Converts a Class to a JSON schema.
  #
  # @return [String] The JSON schema representation of the class's initialize method.
  def to_json_schema
    ToolTailor.convert(self)
  end
end