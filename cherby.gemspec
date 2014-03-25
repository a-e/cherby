Gem::Specification.new do |s|
  s.name = "cherby"
  s.version = "0.0.2"
  s.summary = "Cherwell-Ruby bridge"
  s.description = <<-EOS
    Cherby is a Ruby wrapper for the Cherwell Web Service.
  EOS
  s.authors = ["Eric Pierce"]
  s.email = "wapcaplet88@gmail.com"
  s.homepage = "http://github.com/a-e/cherby"
  s.platform = Gem::Platform::RUBY

  s.add_dependency "httpclient"
  s.add_dependency 'savon', '>= 2.3.0'
  s.add_dependency 'yajl-ruby'
  s.add_dependency 'nokogiri'

  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'

  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'
end

