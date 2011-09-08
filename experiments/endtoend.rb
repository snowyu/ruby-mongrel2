#!/usr/bin/env ruby

# The first end-to-end test of the connection and request objects

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'mongrel2'
require 'logger'


Mongrel2.log.level = Logger::DEBUG

# uuid = 'F6C47DAA-0ECD-4B90-91F9-9F12547657C2'
uuid = 'D613E7EE-E2EB-4699-A200-5C8ECAB45D5E'
recv_port = 'tcp://127.0.0.1:9998'
resp_port = 'tcp://127.0.0.1:9999'

conn = Mongrel2::Connection.new( uuid, recv_port, resp_port )
running = true

Signal.trap( :INT ) { running = false; conn.close }
Signal.trap( :TERM ) { running = false; conn.close }

while running
	$stderr.puts "Accept loop!"
	req = conn.receive
	$stderr.puts "Got request: %p" % [ req ]

	res = req.response
	res.status = 200
	res.headers.content_type = 'text/plain'
	res.body = "Hi there!"

	$stderr.puts "Sending response: %p" % [ res ]
	conn.reply( res )

	$stderr.puts "Done sending!"
end


