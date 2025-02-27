# ToolTailor Development Guide

## Tool Purpose
ToolTailor is a focused Ruby gem that converts Ruby methods with YARD documentation into JSON schemas compatible with OpenAI and Anthropic tool calling APIs. It's a building block that allows you to generate API-compatible tool descriptions from your existing code methods.

## Common Commands
- Run all tests: `bundle exec rake spec`
- Run a specific test: `bundle exec rspec spec/tool_tailor_spec.rb:LINE_NUMBER` (e.g., `bundle exec rspec spec/tool_tailor_spec.rb:60`)
- Run with specific line: `bundle exec rspec spec/tool_tailor_spec.rb -l LINE_NUMBER`
- Build gem: `bundle exec rake build`
- Install gem locally: `bundle exec rake install`
- Release gem: `bundle exec rake release`
- Interactive console: `bin/console`

## Key Features
- Method-level conversion only (no class-level conversion)
- Support for optional and required parameters
- YARD documentation to JSON schema mapping
- Enum values support via custom `@values` tag
- Array items type support via `@items_type` tag
- Array constraints via `@min_items` and `@max_items` tags
- Format output as JSON string or Ruby hash
- Batch conversion of multiple methods
- Robust error handling and debugging options

## Code Style Guidelines
- Use 2-space indentation
- Follow standard Ruby style conventions
- Document methods with YARD
- Type definitions: `@param name [Type] Description`
- Enum values: `@values param_name ["Value1", "Value2"]` tag
- Array items: `@items_type param_name Type` tag
- Array constraints: `@min_items param_name 1` and `@max_items param_name 5` tags
- Error handling: Raise specific errors with clear messages
- Naming: Snake_case for methods/variables, CamelCase for classes/modules
- Method signature: Use named parameters (keyword arguments)

## Limitations
- Only supports named parameters (keyword arguments)
- Does not support nested object properties
- Object types are treated as generic objects without additional schema validation

## Testing Guidelines
- Write both unit and integration tests
- Test error conditions explicitly
- Use descriptive test names
- Test with various parameter combinations and types