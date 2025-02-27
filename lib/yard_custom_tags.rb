# frozen_string_literal: true

require "yard"
require "json"

module YARD
  module Tags
    # Custom tag class for handling `@values` tags.
    # This tag is used to specify allowed values for a parameter (enum in JSON Schema)
    class ValuesTag < YARD::Tags::Tag
      TAG_FORMAT = /^(\S+)\s+\[(.+)\]$/

      # Initialize a new ValuesTag
      #
      # @param tag_name [String] The name of the tag
      # @param text [String] The tag text in the format "param_name [value1, value2, ...]"
      def initialize(tag_name, text)
        name, values = parse_text(text)
        super(tag_name, values, nil, name)
      end

      private

      # Parses the text to match the expected format and extract the name and values.
      #
      # @param text [String] The tag text
      # @return [Array<String, Array>] The parameter name and array of values
      # @raise [ArgumentError] If the text doesn't match the expected format
      def parse_text(text)
        match = text.match(TAG_FORMAT)
        unless match
          raise ArgumentError, "Invalid @values tag format. Expected: @values param_name [value1, value2, ...]"
        end

        name, values_text = match.captures
        values = parse_values(values_text)
        [name, values]
      end

      # Parses the values text as a JSON array
      #
      # @param values_text [String] The values text (without the enclosing brackets)
      # @return [Array] The parsed values
      # @raise [ArgumentError] If the values text isn't valid JSON
      def parse_values(values_text)
        json_text = "[#{values_text}]"
        JSON.parse(json_text)
      rescue JSON::ParserError => e
        raise ArgumentError, "Invalid values format: #{e.message}"
      end
    end
    
    # Custom tag class for handling `@items_type` tags.
    # This tag is used to specify the type of items in an array parameter
    class ItemsTypeTag < YARD::Tags::Tag
      TAG_FORMAT = /^(\S+)\s+(\w+)$/
      VALID_TYPES = %w[String Integer Float Boolean Object Array Null].freeze
      
      # Initialize a new ItemsTypeTag
      #
      # @param tag_name [String] The name of the tag
      # @param text [String] The tag text in the format "param_name type"
      def initialize(tag_name, text)
        name, type = parse_text(text)
        super(tag_name, type, nil, name)
      end
      
      private
      
      # Parses the text to match the expected format and extract the name and type.
      #
      # @param text [String] The tag text
      # @return [Array<String, String>] The parameter name and type
      # @raise [ArgumentError] If the text doesn't match the expected format
      def parse_text(text)
        match = text.match(TAG_FORMAT)
        unless match
          raise ArgumentError, "Invalid @items_type tag format. Expected: @items_type param_name type"
        end
        
        name, type = match.captures
        validate_type(type)
        [name, type]
      end
      
      # Validates that the type is one of the allowed types
      #
      # @param type [String] The type to validate
      # @raise [ArgumentError] If the type is not valid
      def validate_type(type)
        return if VALID_TYPES.include?(type)
        
        raise ArgumentError, "Invalid type '#{type}'. Expected one of: #{VALID_TYPES.join(', ')}"
      end
    end
    
    # Custom tag class for handling `@min_items` tags.
    # This tag is used to specify the minimum number of items in an array parameter
    class MinItemsTag < YARD::Tags::Tag
      TAG_FORMAT = /^(\S+)\s+(\d+)$/
      
      # Initialize a new MinItemsTag
      #
      # @param tag_name [String] The name of the tag
      # @param text [String] The tag text in the format "param_name number"
      def initialize(tag_name, text)
        name, min_items = parse_text(text)
        super(tag_name, min_items, nil, name)
      end
      
      private
      
      # Parses the text to match the expected format and extract the name and minimum items.
      #
      # @param text [String] The tag text
      # @return [Array<String, Integer>] The parameter name and minimum items
      # @raise [ArgumentError] If the text doesn't match the expected format
      def parse_text(text)
        match = text.match(TAG_FORMAT)
        unless match
          raise ArgumentError, "Invalid @min_items tag format. Expected: @min_items param_name number"
        end
        
        name, min_items_text = match.captures
        min_items = min_items_text.to_i
        validate_min_items(min_items)
        [name, min_items]
      end
      
      # Validates that the minimum items is a non-negative integer
      #
      # @param min_items [Integer] The minimum items to validate
      # @raise [ArgumentError] If the minimum items is negative
      def validate_min_items(min_items)
        return if min_items >= 0
        
        raise ArgumentError, "Invalid minimum items '#{min_items}'. Must be a non-negative integer"
      end
    end
    
    # Custom tag class for handling `@max_items` tags.
    # This tag is used to specify the maximum number of items in an array parameter
    class MaxItemsTag < YARD::Tags::Tag
      TAG_FORMAT = /^(\S+)\s+(\d+)$/
      
      # Initialize a new MaxItemsTag
      #
      # @param tag_name [String] The name of the tag
      # @param text [String] The tag text in the format "param_name number"
      def initialize(tag_name, text)
        name, max_items = parse_text(text)
        super(tag_name, max_items, nil, name)
      end
      
      private
      
      # Parses the text to match the expected format and extract the name and maximum items.
      #
      # @param text [String] The tag text
      # @return [Array<String, Integer>] The parameter name and maximum items
      # @raise [ArgumentError] If the text doesn't match the expected format
      def parse_text(text)
        match = text.match(TAG_FORMAT)
        unless match
          raise ArgumentError, "Invalid @max_items tag format. Expected: @max_items param_name number"
        end
        
        name, max_items_text = match.captures
        max_items = max_items_text.to_i
        validate_max_items(max_items)
        [name, max_items]
      end
      
      # Validates that the maximum items is a positive integer
      #
      # @param max_items [Integer] The maximum items to validate
      # @raise [ArgumentError] If the maximum items is not positive
      def validate_max_items(max_items)
        return if max_items > 0
        
        raise ArgumentError, "Invalid maximum items '#{max_items}'. Must be a positive integer"
      end
    end
  end
end

# Register the custom tags
YARD::Tags::Library.define_tag("Allowed values for a parameter", :values, YARD::Tags::ValuesTag)
YARD::Tags::Library.define_tag("Type of items in an array parameter", :items_type, YARD::Tags::ItemsTypeTag)
YARD::Tags::Library.define_tag("Minimum number of items in an array parameter", :min_items, YARD::Tags::MinItemsTag)
YARD::Tags::Library.define_tag("Maximum number of items in an array parameter", :max_items, YARD::Tags::MaxItemsTag)