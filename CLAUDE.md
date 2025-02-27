# ToolTailor Development Guide

## Common Commands
- Run all tests: `bundle exec rake spec`
- Run a specific test: `bundle exec rspec spec/tool_tailor_spec.rb:LINE_NUMBER` (e.g., `bundle exec rspec spec/tool_tailor_spec.rb:49`)
- Run with specific line: `bundle exec rspec spec/tool_tailor_spec.rb -l LINE_NUMBER`
- Build gem: `bundle exec rake build`
- Install gem locally: `bundle exec rake install`
- Release gem: `bundle exec rake release`
- Interactive console: `bin/console`

## Code Style Guidelines
- Use 2-space indentation
- Follow standard Ruby style conventions
- Document methods with YARD 
- Type definitions in YARD: Use `@param name [Type] Description`
- Enum values: Use `@values param_name ["Value1", "Value2"]` tag
- Error handling: Raise specific errors with clear messages
- Naming: Snake_case for methods/variables, CamelCase for classes/modules
- Return values: Document using YARD `@return` tag
- Method signature: Use named parameters with required/optional attributes

## Testing Guidelines
- Write both unit and integration tests
- Test error conditions explicitly
- Use descriptive test names
- Follow RSpec best practices with clear expectations