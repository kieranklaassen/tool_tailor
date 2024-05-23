require "tool_tailor/version"
require 'json'
require 'yard'

module ToolTailor
  class Error < StandardError; end

  # Converts a function to a JSON schema representation.
  #
  # @param function [Method] The function to convert.
  # @return [String] The JSON schema representation of the function.
  # @raise [ArgumentError] If the provided object is not a Method or UnboundMethod.
  def self.convert(function)
    unless function.is_a?(Method) || function.is_a?(UnboundMethod)
      raise ArgumentError, "Unsupported object type: #{function.class}"
    end

    file_path, line_number = function.source_location
    YARD.parse(file_path)

    # Construct the correct identifier for the YARD object
    method_path = "#{function.owner}##{function.name}"
    yard_object = YARD::Registry.at(method_path)
    raise "Documentation for #{method_path} not found." if yard_object.nil?

    function_description = yard_object.docstring

    parameters = yard_object.tags('param').map do |tag|
      {
        name: tag.name,
        type: type_mapping(tag.types.first),
        description: tag.text
      }
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
                description: param[:description]
              }
            ]
          end.to_h,
          required: parameters.map { |param| param[:name].to_s }
        }
      }
    }.to_json
  end

  # Maps Ruby types to JSON schema types.
  #
  # @param type [Class] The Ruby type to map.
  # @return [String] The corresponding JSON schema type.
  # @raise [ArgumentError] If the provided type is not supported.
  def self.type_mapping(type)
    case type
    when "String"
      'string'
    when "Integer"
      'integer'
    when "Float"
      'number'
    when "TrueClass", "FalseClass"
      'boolean'
    when "Array"
      'array'
    when "Hash"
      'object'
    when "NilClass"
      'null'
    else
      # raise ArgumentError, "Unsupported type: #{type} #{type.class}"
      'string'
    end
  end
end
