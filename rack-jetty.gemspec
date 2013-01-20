lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rack_jetty/version'

Gem::Specification.new do |s|
  s.name = %q{rack-jetty}
  s.version = RackJetty::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Graham Batty"]
  s.date = %q{2011-05-09}
  s.description = %q{Allows you to use Jetty as a Rack adapter in JRuby. Compatible with rackup and rails' Rack support.}
  s.email = %q{graham@stormbrew.ca}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "Gemfile",
    "lib/rack/handler/jetty.rb",
    "lib/rack_jetty/jars/core-3.1.1.jar",
    "lib/rack_jetty/jars/jetty-6.1.14.jar",
    "lib/rack_jetty/jars/jetty-plus-6.1.14.jar",
    "lib/rack_jetty/jars/jetty-util-6.1.14.jar",
    "lib/rack_jetty/jars/jsp-2.1.jar",
    "lib/rack_jetty/jars/jsp-api-2.1.jar",
    "lib/rack_jetty/jars/servlet-api-2.5-6.1.14.jar",
    "lib/rack_jetty/java_input.rb",
    "lib/rack_jetty/servlet_handler.rb",
    "lib/rack_jetty/version.rb",
    "spec/images/image.jpg",
    "spec/rack_handler_jetty_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/stormbrew/rack-jetty}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Very simple (mostly Ruby) implementation of jetty as a pure Rack adapter.}

  s.add_development_dependency(%q<rspec>, ["~> 2.0"])
  s.add_development_dependency(%q<rake>, ["~> 10.0"])
  s.add_runtime_dependency(%q<rack>, ["~> 1.0"])
end

