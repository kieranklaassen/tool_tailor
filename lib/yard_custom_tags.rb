require "yard"

module YARD
  module Tags
    # Custom tag class for handling `@values` tags.
    class ValuesTag < YARD::Tags::Tag
      TAG_FORMAT = /^(\S+)\s+\[(.+)\]$/

      def initialize(tag_name, text)
        name, values = parse_text(text)
        super(tag_name, values, nil, name)
      end

      private

      # Parses the text to match the expected format and extract the name and values.
      def parse_text(text)
        match = text.match(TAG_FORMAT)
        unless match
          raise ArgumentError, "Invalid @values tag format. Expected: @values <name> [value1, value2, ...]. Values should be a JSON array."
        end

        name, values_text = match.captures
        values = parse_values(values_text)
        [name, values]
      end

      # Parses the values text as a JSON array to ensure correct types.
      def parse_values(values_text)
        json_text = "[#{values_text}]"
        JSON.parse(json_text)
      rescue JSON::ParserError => e
        raise ArgumentError, "Invalid values format: #{e.message}"
      end
    end

    class Library
      def self.define_custom_tag
        # Defines a new custom tag `@values` using the ValuesTag class.
        YARD::Tags::Library.define_tag("Values", :values, ValuesTag)
      end
    end
  end
end

YARD::Tags::Library.define_custom_tag
