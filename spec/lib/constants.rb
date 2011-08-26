#!/usr/bin/env ruby

require 'yajl'
require 'tnetstring'

require 'mongrel2' unless defined?( Mongrel2 )


### A collection of constants used in testing
module Mongrel2::TestConstants # :nodoc:all

	include Mongrel2::Constants

	unless defined?( TEST_HOST )

		TEST_HOST = 'localhost'
		TEST_PORT = 8118

		# Rule 2: Every message to and from Mongrel2 has that Mongrel2 instances
		#   UUID as the very first thing.
		TEST_UUID = 'BD17D85C-4730-4BF2-999D-9D2B2E0FCCF9'

		# Rule 3: Mongrel2 sends requests with one number right after the
		#   servers UUID separated by a space. Handlers return a netstring with
		#   a list of numbers separated by spaces. The numbers indicate the
		#   connected browser the message is to/from.
		TEST_ID = 8

		# Rule 4: Requests have the path as a single string followed by a
		#   space and no paths may have spaces in them.
		TEST_PATH = '/the/bear/necessities+of+life'

		TEST_HEADERS = {
			'Accept' => 'text/html, text/plain, */*',
			'Host' => 'demo.example.com',
		}
		TEST_HEADERS_TNETSTRING = TNetstring.dump( TEST_HEADERS )
		TEST_HEADERS_JSONSTRING = TNetstring.dump( Yajl::Encoder.encode(TEST_HEADERS) )

		TEST_BODY = ''
		TEST_BODY_TNETSTRING = TNetstring.dump( TEST_BODY )


		constants.each do |cname|
			const_get(cname).freeze
		end
	end

end


