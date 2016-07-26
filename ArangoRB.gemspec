lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = "ArangoRB"
  s.version	    = "0.0.0"
  s.authors     = ["Stefano Martin"]
  s.email       = ["stefano@seluxit.com"]
  s.homepage    = 'https://github.com/StefanoMartin/ArangoRB'
  s.licenses    = ['MIT']
  s.summary     = 'A simple ruby client for ArangoDB'
  s.description = 'ArangoDB is a powerful mixed database based on documents and graphs, with an interesting language called AQl. ArangoRB is a Ruby gems to use Ruby to interact with its HTTP API.'
  s.platform	   = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.3.1'
  s.date 	        = "2016-7-26"
  # s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  # s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # s.bindir        = "exe"
  # s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.add_development_dependency "bundler", "~> 1.12.5"
  s.add_development_dependency "rake", "~> 11.2.2"
  s.add_dependency 'httparty', "~> 0.14.0"
end
