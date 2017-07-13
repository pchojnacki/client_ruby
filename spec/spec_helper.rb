# encoding: UTF-8

require 'simplecov'
require 'coveralls'

ENV['prometheus_multiproc_dir'] = 'tmp/'

SimpleCov.formatter =
  if ENV['CI']
    Coveralls::SimpleCov::Formatter
  else
    SimpleCov::Formatter::HTMLFormatter
  end

SimpleCov.start
