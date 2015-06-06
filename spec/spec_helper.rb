require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'concord'
require 'rspec/its'
require 'pry'
require 'pry-nav'
