# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'prometheus/client/version'

Gem::Specification.new do |s|
  s.name              = 'prometheus-client-mmap'
  s.version           = Prometheus::Client::VERSION
  s.summary           = 'A suite of instrumentation metric primitives' \
                        'that can be exposed through a web services interface.'
  s.authors           = ['Tobias Schmidt']
  s.email             = ['ts@soundcloud.com']
  s.homepage          = 'https://gitlab.com/gitlab-org/prometheus-client-mmap'
  s.license           = 'Apache 2.0'

  s.files             = %w(README.md) + Dir.glob('{lib/**/*}')
  s.require_paths     = ['lib']

  s.add_dependency 'mmap2', '~> 2.2.6'
end
