#!/usr/bin/ruby

require 'tnetstring'
require 'yajl'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'
require 'mongrel2/table'


# The Mongrel2 Request class. Instances of this class represent a request from
# a Mongrel2 server.
#
# == Author/s
# * Michael Granger <ged@FaerieMUD.org>
#
class Mongrel2::Request
	include Mongrel2::Loggable


	# The request method to assume if the 'METHOD' header value is invalid.
	DEFAULT_METHOD = 'GET'


	# METHOD header -> request class mapping
	@request_types = Hash.new {|h,k| h[k] = Mongrel2::Request }
	class << self; attr_reader :request_types; end


	### Register the specified +subclass+ as the class to instantiate when the +METHOD+
	### header is one of the specified +req_methods+. This method exists for frameworks
	### which wish to break out different request types by subclassing Mongrel2::Request.
	### For example, if your framework has a JSONRequest class that inherits from
	### Mongrel2::Request, and you want it to be returned from Mongrel2::Request.parse
	### for METHOD=JSON requests:
	###
	###   class MyFramework::JSONRequest < Mongrel2::Request
	###       register_request_type self, 'JSON'
	###       
	###       # Override #initialize to do any stuff specific to your
	###       # request type, but you'll likely want to super() to
	###       # Mongrel2::Request.
	###       def initialize( * )
	###           super
	###           self.body = Yajl.load( self.body )
	###       end
	###
	###   end # class MyFramework::JSONRequest
	###
	### If you wish one of your subclasses to *always* be used instead of
	### Mongrel2::Request, register it with a METHOD of :__default.
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
			Mongrel2.log.debug "  parsing JSON headers"
			headers = Yajl::Parser.parse( headers )
		end

		req_method = if headers['METHOD'] =~ /^(\w+)$/ then $1.untaint else DEFAULT_METHOD end
		concrete_class = self.subclass_for_method( req_method )

		return concrete_class.new( sender, conn_id, path, headers, body )
	end



	### Create a new Request object with the given +sender_id+, +conn_id+, +path+, +headers+, 
	### and +body+.
	def initialize( sender_id, conn_id, path, headers, body )
		@sender_id = sender_id
		@conn_id   = Integer( conn_id )
		@path      = path
		@headers   = Mongrel2::Table.new( headers )
		@body      = body
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


	### Create a Mongrel2::Response that will respond to the same server/connection as
	### the receiver. If you wish your specialized Request class to have a corresponding
	### response type, you can override this method to achieve that.
	def response
		return Mongrel2::Response.from_request( self )
	end

end # class Mongrel2::Request

# vim: set nosta noet ts=4 sw=4:

