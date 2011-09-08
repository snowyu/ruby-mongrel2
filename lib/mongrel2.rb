#!/usr/bin/env ruby

#
# A Mongrel2 handler and configuration library for Ruby.
# 
# = Author/s
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
module Mongrel2

	warn ">>> Mongrel2 requires Ruby 1.9.2 or later. <<<" if RUBY_VERSION < '1.9.2'

	# Library version constant
	VERSION = '0.0.1'

	# Version-control revision constant
	REVISION = %q$Revision$


	require 'mongrel2/logging'
	extend Mongrel2::Logging

	require 'mongrel2/constants'
	include Mongrel2::Constants


	### Get the library version. If +include_buildnum+ is true, the version string will
	### include the VCS rev ID.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end


	# ZMQ::Context (lazy-loaded)
	@zmq_ctx = nil

	### Fetch the ZMQ::Context for sockets, creating it if necessary.
	def self::zmq_context
		if @zmq_ctx.nil?
			Mongrel2.log.info "Using 0MQ %d.%d.%d" % ZMQ.version
			@zmq_ctx = ZMQ::Context.new
		end

		return @zmq_ctx
	end


	require 'mongrel2/exceptions'
	require 'mongrel2/connection'
	require 'mongrel2/request'
	require 'mongrel2/response'
	require 'mongrel2/control'

end # module Mongrel2

