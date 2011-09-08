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

		# 0mq socket specifications for Handlers
		TEST_SEND_SPEC = 'tcp://127.0.0.1:9998'
		TEST_RECV_SPEC = 'tcp://127.0.0.1:9997'

		# Rule 3: Mongrel2 sends requests with one number right after the
		#   servers UUID separated by a space. Handlers return a netstring with
		#   a list of numbers separated by spaces. The numbers indicate the
		#   connected browser the message is to/from.
		TEST_ID = 8

		#
		# HTTP request constants
		#

		TEST_ROUTE = '/handler'
		TEST_PATH  = TEST_ROUTE
		TEST_QUERY = 'thing=foom'

		TEST_HEADERS = {
			"x-forwarded-for" => "127.0.0.1",
			"accept-language" => "en-US,en;q=0.8",
			"accept-encoding" => "gzip,deflate,sdch",
			"connection"      => "keep-alive",
			"accept-charset"  => "UTF-8,*;q=0.5",
			"accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
			"user-agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) " +
			                     "AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.112 " +
			                     "Safari/535.1",
			"host"            => "localhost:3667",
			"METHOD"          => "GET",
			"VERSION"         => "HTTP/1.1",
		}

		TEST_BODY = ''

		TEST_REQUEST_OPTS = {
			:uuid    => TEST_UUID,
			:id      => TEST_ID,
			:path    => TEST_PATH,
			:body    => TEST_BODY,
		}


		#
		# JSON (JSSocket, etc.) request constants
		#

		TEST_JSON_PATH = '@directory'

		TEST_JSON_HEADERS = {
			'PATH'            => TEST_JSON_PATH,
			'x-forwarded-for' => "127.0.0.1",
			'METHOD'          => "JSON",
			'PATTERN'         => TEST_JSON_PATH,
		}
		TEST_JSON_BODY = { 'type' => 'msg', 'msg' => 'connect' }

		TEST_JSON_REQUEST_OPTS = {
			:uuid    => TEST_UUID,
			:id      => TEST_ID,
			:path    => TEST_JSON_PATH,
			:body    => TEST_JSON_BODY,
		}


		# Freeze all testing constants
		constants.each do |cname|
			const_get(cname).freeze
		end
	end

end


