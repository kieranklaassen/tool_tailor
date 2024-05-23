require_relative 'lib/tool_tailor/version'

Gem::Specification.new do |spec|
  spec.name          = "tool_tailor"
  spec.version       = ToolTailor::VERSION
  spec.authors       = ["Kieran Klaassen"]
  spec.email         = ["kieranklaassen@gmail.com"]

  spec.summary       = %q{A Gem to convert methods to openai JSON schemas for use with tools}
  spec.description   = %q{ToolTailor is a Ruby gem that converts methods to OpenAI JSON schemas for use with tools, making it easier to integrate with OpenAI's API.}
  spec.homepage      = "https://github.com/kieranklaassen/tool_tailor"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kieranklaassen/tool_tailor"
  spec.metadata["changelog_uri"] = "https://github.com/kieranklaassen/tool_tailor/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "yard", "~> 0.9.36"
end
