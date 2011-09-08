#!/usr/bin/ruby

require 'mongrel2/request' unless defined?( Mongrel2::Request )
require 'mongrel2/mixins'
require 'mongrel2/httpresponse'


# The Mongrel2 HTTP Request class. Instances of this class represent an HTTP request from
# a Mongrel2 server.
class Mongrel2::HTTPRequest < Mongrel2::Request
	include Mongrel2::Loggable

	# HTTP verbs from RFC2616
	HANDLED_HTTP_METHODS = [ :OPTIONS, :GET, :HEAD, :POST, :PUT, :DELETE, :TRACE, :CONNECT ]

	register_request_type( self, *HANDLED_HTTP_METHODS )


	### Create a Mongrel2::HTTPResponse that corresponds to the receiver.
	def response
		return Mongrel2::HTTPResponse.from_request( self )
	end


	### Return +true+ if the request is an HTTP/1.1 request and its
	### 'Connection' header indicates that the connection should stay
	### open.
	def keepalive?
		return false if self.headers[:version] == 'HTTP/1.0'

		ka_header = self.headers[:connection]
		return !ka_header.nil? && ka_header =~ /keep-alive/i
		return false
	end

end # class Mongrel2::HTTPRequest

# vim: set nosta noet ts=4 sw=4:

