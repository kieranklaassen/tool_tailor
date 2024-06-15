require "tool_tailor/version"
require "json"
require "yard"
require "yard_custom_tags"

module ToolTailor
  class Error < StandardError; end

  # Converts a function to a JSON schema representation.
  #
  # @param function [Method, UnboundMethod] The function to convert.
  # @return [String] The JSON schema representation of the function.
  # @raise [ArgumentError] If the provided object is not a Method or UnboundMethod.
  #
  # @example
  #   def example_method(param1, param2)
  #     # method implementation
  #   end
  #
  #   ToolTailor.convert(method(:example_method))
  def self.convert(function)
    unless function.is_a?(Method) || function.is_a?(UnboundMethod)
      raise ArgumentError, "Unsupported object type: #{function.class}"
    end

    # Ensure only named arguments are allowed
    unless function.parameters.all? { |type, _| type == :keyreq || type == :key }
      raise ArgumentError, "Only named arguments are supported"
    end

    file_path, line_number = function.source_location
    YARD.parse(file_path)

    method_path = "#{function.owner}##{function.name}"
    yard_object = YARD::Registry.at(method_path)

    # Extract parameters from the function definition
    parameters = function.parameters.map do |_, name|
      {
        name: name.to_s,
        type: "string",
        description: "",
        enum: nil
      }
    end

    function_description = ""

    if yard_object
      function_description = yard_object.docstring

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
        name: function.name.to_s,
        description: function_description,
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
          required: function.parameters.select { |type, _| type == :keyreq }.map { |_, name| name.to_s }
        }
      }
    }.to_json
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
  # @example
  #   class ExampleClass
  #     # @param name [String] The name of the person.
  #     # @param age [Integer] The age of the person.
  #     def greet(name, age)
  #       puts "Hello, #{name}! You are #{age} years old."
  #     end
  #   end
  #
  #   ExampleClass.instance_method(:greet).to_json_schema
  #   # => {
  #   #   "type" => "function",
  #   #   "function" => {
  #   #     "name" => "greet",
  #   #     "description" => "",
  #   #     "parameters" => {
  #   #       "type" => "object",
  #   #       "properties" => {
  #   #         "name" => {
  #   #           "type" => "string",
  #   #           "description" => "The name of the person."
  #   #         },
  #   #         "age" => {
  #   #           "type" => "integer",
  #   #           "description" => "The age of the person."
  #   #         }
  #   #       },
  #   #       "required" => ["name", "age"]
  #   #     }
  #   #   }
  #   # }
  #
  # @return [String] The JSON schema representation of the method.
  def to_json_schema
    ToolTailor.convert(self)
  end
end

class Method
  # Converts a Method to a JSON schema.
  #
  # @example
  #   class ExampleClass
  #     # @param name [String] The name of the person.
  #     # @param age [Integer] The age of the person.
  #     def greet(name, age)
  #       puts "Hello, #{name}! You are #{age} years old."
  #     end
  #   end
  #
  #   ExampleClass.new.method(:greet).to_json_schema
  #   # => {
  #   #   "type" => "function",
  #   #   "function" => {
  #   #     "name" => "greet",
  #   #     "description" => "",
  #   #     "parameters" => {
  #   #       "type" => "object",
  #   #       "properties" => {
  #   #         "name" => {
  #   #           "type" => "string",
  #   #           "description" => "The name of the person."
  #   #         },
  #   #         "age" => {
  #   #           "type" => "integer",
  #   #           "description" => "The age of the person."
  #   #         }
  #   #       },
  #   #       "required" => ["name", "age"]
  #   #     }
  #   #   }
  #   # }
  #
  # @return [String] The JSON schema representation of the method.
  def to_json_schema
    ToolTailor.convert(self)
  end
end
