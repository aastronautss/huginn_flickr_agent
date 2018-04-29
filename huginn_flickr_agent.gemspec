# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'huginn_flickr_agent'
  spec.version       = '0.1'
  spec.authors       = ['Tyler Guillen']
  spec.email         = ['tyguillen@gmail.com']

  spec.summary       = 'The Huginn Flickr agent provides interactions with the Flickr API.'
  spec.description   = 'The Huginn Flickr agent provides interactions with the Flickr API.'

  spec.homepage      = 'https://github.com/[my-github-username]/huginn_flickr_agent'

  spec.license       = 'MIT'

  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'huginn_agent'
  spec.add_runtime_dependency 'flickraw'
  spec.add_runtime_dependency 'omniauth-flickr'
end
