#!/usr/bin/env ruby


# A Mongrel2 handler and configuration library for Ruby.
# 
# = Author/s
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
module Mongrel2

	# Library version constant
	VERSION = '0.0.1'

	# Version-control revision constant
	REVISION = %q$Revision$

	require 'mongrel2/logging'
	extend Mongrel2::Logging


	### Get the Treequel version. If +include_buildnum+ is true, the version string will
	### include the VCS rev ID.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end


end # module Mongrel2

