#!/usr/bin/ruby
#encoding: utf-8

require 'pathname'
require 'mongrel2' unless defined?( Mongrel2 )


# A collection of constants that are shared across the library
module Mongrel2::Constants

	# The path to the default Sqlite configuration database
	DEFAULT_CONFIG_URI = 'config.sqlite'

	# Maximum number of identifiers that can be included in a broadcast response
	MAX_BROADCAST_IDENTS = 100

end # module Mongrel2::Constants

