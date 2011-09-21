#!/usr/bin/ruby

require 'tnetstring'
require 'yajl'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'


# The Mongrel2 Response base class.
class Mongrel2::Response
	include Mongrel2::Loggable

	# The default number of bytes of the response body to send to the mongrel2
	# server at a time.
	DEFAULT_CHUNKSIZE = 1024 * 512


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

	# The body of the response
	attr_accessor :body


	### Append the given +object+ to the response body. Returns the response for
	### chaining.
	def <<( object )
		self.body << object
		return self
	end


	### Write the given +objects+ to the response body, calling #to_s on each one.
	def puts( *objects )
		objects.each do |obj|
			self << obj.to_s.chomp << $/
		end
	end


	### Stringify the response, which just returns its body.
	def to_s
		return self.body
	end

	### Returns a string containing a human-readable representation of the Response,
	### suitable for debugging.
	def inspect
		return "#<%p:0x%016x %s (%s/%d)>" % [
			self.class,
			self.object_id * 2,
			self.inspect_details,
			self.sender_id,
			self.conn_id
		]
	end


	#########
	protected
	#########

	### Return the details to include in the contents of the #inspected object. This
	### method allows other request types to provide their own details while keeping
	### the form somewhat consistent.
	def inspect_details
		return "%p body" % [ self.body.class ]
	end

end # class Mongrel2::Response

# vim: set nosta noet ts=4 sw=4:

