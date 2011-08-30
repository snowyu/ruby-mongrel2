#!/usr/bin/ruby

require 'tnetstring'
require 'yajl'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'


# The Mongrel2 Response base class.
#
# == Author/s
# * Michael Granger <ged@FaerieMUD.org>
#
class Mongrel2::Response
	include Mongrel2::Loggable

	### Create a response to the specified +request+ and return it.
	def self::from_request( request )
		Mongrel2.log.debug "Creating a %p to request %p" % [ self, request ]
		return new( request.sender_id, request.conn_id )
	end


	### Create a new Response object for the specified +sender_id+, +conn_id+, and +body+.
	def initialize( sender_id, conn_id, body='' )
		@sender_id = sender_id
		@conn_id   = conn_id
		@body      = body
	end


	######
	public
	######

	# The response's UUID; this corresponds to the mongrel2 server the response will
	# be routed to by the Connection.
	attr_accessor :sender_id

	# The response's connection ID; this corresponds to the identifier of the connection
	# the response will be routed to by the mongrel2 server
	attr_accessor :conn_id


	### Return the Stringified body of the response. Overridden by subclasses
	### to include headers, etc.
	def body
		return @body
	end

end # class Mongrel2::Response

# vim: set nosta noet ts=4 sw=4:

