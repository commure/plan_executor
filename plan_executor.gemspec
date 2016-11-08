# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "plan_executor"
  s.summary = "A Gem for handling FHIR test executions"
  s.description = "A Gem for handling FHIR test executions"
  s.email = "aquina@mitre.org"
  s.homepage = "https://github.com/hl7-fhir/fhir-svn"
  s.authors = ["Andre Quina", "Jason Walonoski", "Janoo Fernandes"]
  s.version = '1.0.0'

  s.files = s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency('nokogiri')
  s.add_runtime_dependency('nokogiri-diff')
  s.add_runtime_dependency('fhir_models')
  s.add_runtime_dependency('fhir_client')
  s.add_runtime_dependency('ansi')
  s.add_runtime_dependency('method_source')
end
