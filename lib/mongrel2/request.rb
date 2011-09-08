#!/usr/bin/ruby

require 'tnetstring'
require 'yajl'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'
require 'mongrel2/table'


# The Mongrel2 Request base class. Derivatives of this class represent a request from
# a Mongrel2 server.
class Mongrel2::Request
	include Mongrel2::Loggable


	# METHOD header -> request class mapping
	@request_types = Hash.new {|h,k| h[k] = Mongrel2::Request }
	class << self; attr_reader :request_types; end


	### Register the specified +subclass+ as the class to instantiate when the +METHOD+
	### header is one of the specified +req_methods+. This method exists for frameworks
	### which wish to provide their own Request types.
	###
	### For example, if your framework has a JSONRequest class that inherits from
	### Mongrel2::JSONRequest, and you want it to be returned from Mongrel2::Request.parse
	### for METHOD=JSON requests:
	###
	###   class MyFramework::JSONRequest < Mongrel2::JSONRequest
	###       register_request_type self, 'JSON'
	###       
	###       # Override #initialize to do any stuff specific to your
	###       # request type, but you'll likely want to super() to
	###       # Mongrel2::JSONRequest.
	###       def initialize( * )
	###           super
	###           # Do some other stuff
	###       end
	###
	###   end # class MyFramework::JSONRequest
	###
	### If you wish one of your subclasses to be used instead of Mongrel2::Request 
	### for the default request class, register it with a METHOD of :__default.
	def self::register_request_type( subclass, *req_methods )
		req_methods.each do |methname|
			if methname == :__default
				# Clear cached lookups
				Mongrel2.log.info "Registering %p as the default request type." % [ subclass ]
				Mongrel2::Request.request_types.delete_if {|_, klass| klass == Mongrel2::Request }
				Mongrel2::Request.request_types.default_proc = lambda {|h,k| h[k] = subclass }
			else
				Mongrel2.log.info "Registering %p for the %p method." % [ subclass, methname ]
				Mongrel2::Request.request_types[ methname.to_sym ] = subclass
			end
		end
	end


	### Return the Mongrel2::Request class registered for the request method +methname+.
	def self::subclass_for_method( methname )
		return Mongrel2::Request.request_types[ methname.to_sym ]
	end


	### Parse the given +raw_request+ from a Mongrel2 server and return an appropriate
	### request object.
	def self::parse( raw_request )
		sender, conn_id, path, rest = raw_request.split( ' ', 4 )
		Mongrel2.log.debug "Parsing request for %p from %s:%s (rest: %p)" %
			[ path, sender, conn_id, rest ]

		# Extract the headers and the body, ignore the rest
		headers, rest = TNetstring.parse( rest )
		body, _       = TNetstring.parse( rest )

		# Headers will be a JSON String when not using the TNetString protocol
		if headers.is_a?( String )
			Mongrel2.log.debug "  parsing old-style headers"
			headers = Yajl::Parser.parse( headers )
		end

		# This isn't supposed to happen, but guard against it anyway
		headers['METHOD'] =~ /^(\w+)$/ or
			raise Mongrel2::UnhandledMethodError, headers['METHOD']
		req_method = $1.untaint.to_sym
		Mongrel2.log.debug "Request method is: %p" % [ req_method ]
		concrete_class = self.subclass_for_method( req_method )

		return concrete_class.new( sender, conn_id, path, headers, body, raw_request )
	end



	### Create a new Request object with the given +sender_id+, +conn_id+, +path+, +headers+, 
	### and +body+. The optional +nil+ is for the raw request content, which can be useful
	### later for debugging.
	def initialize( sender_id, conn_id, path, headers, body, raw=nil )
		@sender_id = sender_id
		@conn_id   = Integer( conn_id )
		@path      = path
		@headers   = Mongrel2::Table.new( headers )
		@body      = body

		@raw       = raw
	end


	######
	public
	######

	# The UUID of the requesting mongrel server
	attr_reader :sender_id

	# The listener ID on the server
	attr_reader :conn_id

	# The path component of the requested URL in HTTP, or the equivalent 
	# for other request types
	attr_reader :path

	# The Mongrel2::Table object that contains the request headers
	attr_reader :headers

	# The request body data, if there is any, as a String
	attr_reader :body

	# The raw request content, if the request was parsed from mongrel2
	attr_reader :raw


	### Create a Mongrel2::Response that will respond to the same server/connection as
	### the receiver. If you wish your specialized Request class to have a corresponding
	### response type, you can override this method to achieve that.
	def response
		return Mongrel2::Response.from_request( self )
	end

	### Return +true+ if the request is a special 'disconnect' notification from Mongrel2.
	def is_disconnect?
		return false
	end

end # class Mongrel2::Request

# vim: set nosta noet ts=4 sw=4:

