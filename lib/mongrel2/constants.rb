#!/usr/bin/ruby
#encoding: utf-8

require 'pathname'
require 'mongrel2' unless defined?( Mongrel2 )


### A collection of constants that are shared across the library
module Mongrel2::Constants

	DEFAULT_CONFIG_URI = 'sqlite:config.sqlite'

end # module Mongrel2::Constants

