# frozen_string_literal: true

module ToolTailor
  # Base error class for all ToolTailor errors
  class Error < StandardError; end
  
  # Raised when there's an error parsing the type
  class TypeError < Error; end
  
  # Raised when there's an error parsing YARD documentation
  class ParseError < Error; end
end