#!/usr/bin/env ruby

require 'uri'
require 'pathname'
require 'mongrel2'
require 'mongrel2/handler'


# A collection of constants and functions for testing Mongrel2 applications,
# as well as Mongrel2 itself.

module Mongrel2

	### A collection of helper functions that are generally useful
	### for testing Mongrel2::Handlers.
	module SpecHelpers
	end # module SpecHelpers


	### A factory for generating Mongrel2::Request objects for testing.
	class RequestFactory

		# Default testing UUID (sender_id)
		DEFAULT_TEST_UUID = 'BD17D85C-4730-4BF2-999D-9D2B2E0FCCF9'

		# Default connection ID
		DEFAULT_CONN_ID = 0

		# 0mq socket specifications for Handlers
		TEST_SEND_SPEC = 'tcp://127.0.0.1:9998'
		TEST_RECV_SPEC = 'tcp://127.0.0.1:9997'

		# The testing URL to use by default
		DEFAULT_TESTING_URL   = URI( 'http://localhost:8080/a_handler' )

		DEFAULT_TESTING_HOST  = DEFAULT_TESTING_URL.host
		DEFAULT_TESTING_PORT  = DEFAULT_TESTING_URL.port
		DEFAULT_TESTING_ROUTE = DEFAULT_TESTING_URL.path

		# The default set of headers used for HTTP requests
		DEFAULT_TESTING_HEADERS  = {
			"x-forwarded-for" => "127.0.0.1",
			"accept-language" => "en-US,en;q=0.8",
			"accept-encoding" => "gzip,deflate,sdch",
			"connection"      => "keep-alive",
			"accept-charset"  => "UTF-8,*;q=0.5",
			"accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
			"user-agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) " +
			                     "AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.112 " +
			                     "Safari/535.1",
			"VERSION"         => "HTTP/1.1",
		}

		# The defaults used by the HTTP request factory
		DEFAULT_FACTORY_CONFIG = {
			:sender_id => DEFAULT_TEST_UUID,
			:conn_id   => DEFAULT_CONN_ID,
			:host      => DEFAULT_TESTING_HOST,
			:port      => DEFAULT_TESTING_PORT,
			:route     => DEFAULT_TESTING_ROUTE,
			:headers   => DEFAULT_TESTING_HEADERS,
		}

		# Freeze all testing constants
		constants.each do |cname|
			const_get(cname).freeze
		end


		### Create a new RequestFactory with the given +config+, which will be merged with
		### DEFAULT_FACTORY_CONFIG.
		def initialize( config={} )
			config[:headers] = DEFAULT_TESTING_HEADERS.merge( config[:headers] ) if config[:headers]
			config = DEFAULT_FACTORY_CONFIG.merge( config )

			@sender_id = config[:sender_id]
			@host      = config[:host]
			@port      = config[:port]
			@route     = config[:route]
			@headers   = Mongrel2::Table.new( config[:headers] )

			@conn_id = 0
		end

		######
		public
		######

		attr_accessor :sender_id, :host, :port, :route, :conn_id
		attr_reader :headers

		#
		# :section: HTTP verb methods
		#

		### Create a new OPTIONS Mongrel2::Request with the specified +uri+ and +headers+.
		def options( uri, headers={} )
			raise "Request doesn't route through %p" % [ self.route ] unless
				uri.start_with?( self.route )

			headers = self.make_merged_headers( :OPTIONS, uri, headers )
			rclass = Mongrel2::Request.subclass_for_method( :OPTIONS )

			return rclass.new( self.sender_id, self.conn_id.to_s, uri.to_s, headers )
		end


		### Create a new GET Mongrel2::Request for the specified +uri+ and +headers+.
		def get( uri, headers={} )
			raise "Request doesn't route through %p" % [ self.route ] unless
				uri.start_with?( self.route )

			headers = self.make_merged_headers( :GET, uri, headers )
			rclass = Mongrel2::Request.subclass_for_method( :GET )

			return rclass.new( self.sender_id, self.conn_id.to_s, uri.to_s, headers )
		end


		### Create a new HEAD Mongrel2::Request for the specified +uri+ and +headers+.
		def head( uri, headers={} )
			raise "Request doesn't route through %p" % [ self.route ] unless
				uri.start_with?( self.route )

			headers = self.make_merged_headers( :HEAD, uri, headers )
			rclass = Mongrel2::Request.subclass_for_method( :HEAD )

			return rclass.new( self.sender_id, self.conn_id.to_s, uri.to_s, headers )
		end


		### Create a new POST Mongrel2::Request for the specified +uri+ with
		### the given +body+ and +headers+.
		def post( uri, body='', headers={} )
			raise "Request doesn't route through %p" % [ self.route ] unless
				uri.start_with?( self.route )

			headers = self.make_merged_headers( :POST, uri, headers )
			rclass = Mongrel2::Request.subclass_for_method( :POST )

			req = rclass.new( self.sender_id, self.conn_id.to_s, uri.to_s, headers )
			req.body = body

			return req
		end


		### Create a new PUT Mongrel2::Request for the specified +uri+ with
		### the given +body+ and +headers+.
		def put( uri, body='', headers={} )
			raise "Request doesn't route through %p" % [ self.route ] unless
				uri.start_with?( self.route )

			headers = self.make_merged_headers( :PUT, uri, headers )
			rclass = Mongrel2::Request.subclass_for_method( :PUT )

			req = rclass.new( self.sender_id, self.conn_id.to_s, uri.to_s, headers )
			req.body = body

			return req
		end


		### Create a new DELETE Mongrel2::Request for the specified +uri+ with
		### the given +headers+.
		def delete( uri, headers={} )
			raise "Request doesn't route through %p" % [ self.route ] unless
				uri.start_with?( self.route )

			headers = self.make_merged_headers( :DELETE, uri, headers )
			rclass = Mongrel2::Request.subclass_for_method( :DELETE )

			return rclass.new( self.sender_id, self.conn_id.to_s, uri.to_s, headers )
		end


		#########
		protected
		#########

		### Merge the factory's headers with +userheaders+, and then merge in the
		### special headers that Mongrel2 adds that are based on the +uri+ and other
		### server attributes.
		def make_merged_headers( verb, uri, userheaders )
			headers = self.headers.merge( userheaders )
			uri = URI( uri )

			# Add mongrel headers
			headers.uri       = uri.to_s
			headers.path      = uri.path
			headers['METHOD'] = verb.to_s
			headers.host      = "%s:%d" % [ self.host, self.port ]
			headers.query     = uri.query if uri.query
			headers.pattern   = self.route

			return headers
		end

	end # RequestFactory

end # module Mongrel2

