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

	### Parse the given +raw_request+ from a Mongrel2 server and return a new Mongrel2::Request
	### object.
	def self::parse( raw_request )
		sender, conn_id, path, rest = raw_request.split( ' ', 4 )
		Mongrel2.log.debug "Parsing request for %p from %s:%s (rest: %p)" %
			[ path, sender, conn_id, rest ]

		headers, rest = TNetstring.parse( rest )
		body, _       = TNetstring.parse( rest )

		if headers.is_a?( String )
			Mongrel2.log.debug "  parsing JSON headers"
			headers = Yajl::Parser.parse( headers )
		end

		return new( sender, conn_id, path, headers, body )
	end


	### Create a new Request object with the given +sender_id+, +conn_id+, +path+, +headers+, 
	### and +body+.
	def initialize( sender_id, conn_id, path, headers, body )
		@sender_id = sender_id
		@conn_id   = Integer( conn_id )
		@path      = path
		@headers   = Mongrel2::Table.new( headers )

		if @headers[:method] == 'JSON'
			@body = Yajl::Parser.parse( body )
		else
			@body = body
		end
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


end # class Mongrel2::Request

# vim: set nosta noet ts=4 sw=4:

