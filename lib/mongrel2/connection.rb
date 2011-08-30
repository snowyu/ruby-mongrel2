#!/usr/bin/ruby

require 'zmq'
require 'yajl'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'


# The Mongrel2 connection class. Connections objects serve as a front end for 
# the ZMQ sockets which talk to the mongrel2 server/s for your handler. It receives 
# raw or JSON-encoded requests and wraps Mongrel2::Request objects around them, and
# then ships Mongrel2::Response objects back to the server.
#
# == Author/s
# * Michael Granger <ged@FaerieMUD.org>
#
# == References
# * http://mongrel2.org/static/mongrel2-manual.html#x1-700005.3
class Mongrel2::Connection
	include Mongrel2::Loggable


	### Create a new Connection identified by +app_id+ (a UUID or other unique string) that
	### will connect to a Mongrel2 server on the +sub_addr+ and +pub_addr+ (e.g., 
	### 'tcp://127.0.0.1:9998').
	def initialize( app_id, sub_addr, pub_addr )
		@app_id   = app_id
		@sub_addr = sub_addr
		@pub_addr = pub_addr

		ctx = Mongrel2.zmq_context

		self.log.info "Connecting request socket (%s)" % [ @sub_addr ]
		@request_sock  = ctx.socket( ZMQ::PULL )
		@request_sock.connect( @sub_addr )

		self.log.info "Connecting response socket (%s)" % [ @pub_addr ]
		@response_sock  = ctx.socket( ZMQ::PUB )
		@response_sock.setsockopt( ZMQ::IDENTITY, @app_id )
		@response_sock.connect( @pub_addr )

		@closed = false
	end


	######
	public
	######

	# The application's UUID that identifies it to Mongrel2
	attr_reader :app_id

	# The connection's subscription (request) socket address
	attr_reader :sub_addr

	# The connection's publication (response) socket address
	attr_reader :pub_addr

	# The ZMQ::PULL socket for incoming requests
	attr_reader :request_sock

	# The ZMQ::PUB socket for outgoing responses
	attr_reader :response_sock

	# True if the Connection to the Mongrel2 server has been closed.
	attr_writer :closed


	### Fetch the next request from the server as raw TNetString data.
	def recv
		self.check_closed

		self.log.debug "Fetching next request"
		data = self.request_sock.recv
		self.log.debug "  got request data: %p" % [ data ]
		return data
	end


	### Fetch the next request from the server as a Mongrel2::Request object.
	def receive
		raw_req = self.recv
		return Mongrel2::Request.parse( raw_req )
	end


	### Write a raw +data+ to the given connection ID (+conn_id+) at the given +sender_id+.
	def send( sender_id, conn_id, data )
		self.check_closed

		conn_id = conn_id.to_s
        header = "%s %d:%s," % [ sender_id, conn_id.length, conn_id ]

		self.log.debug "Sending: %p" % [ header + ' ' + data ]
        self.response_sock.send( header + ' ' + data )
	end


	### Write the specified +response+ (Mongrel::Response object) to the requester.
	def reply( response )
		self.send( response.sender_id, response.conn_id, response.body )
	end


	### Send the given +data+ to one or more connected clients identified by +client_ids+
	### via the server specified by +sender_id+. The +client_ids+ should be an Array of
	### Integer IDs no longer than Mongrel2::MAX_IDENTS.
	def broadcast( sender_id, conn_ids, data )
		idlist = conn_ids.map( &:to_s ).join( ' ' )
		self.send( sender_id, idlist, data )
	end


	### Tell the server to close the connection the +request+ was from.
	def send_close( request )
		self.send( request.sender_id, request.conn_id, '' )
	end


	### Tell the server associated with +sender_id+ to close the connections associated 
	### with +conn_ids+.
	def broadcast_close( sender_id, conn_ids )
		self.broadcast( sender_id, conn_ids, '' )
	end


	### Close both of the sockets and mark the Connection as closed.
	def close
		return if self.closed?
		self.closed = true
		self.request_sock.close
		self.response_sock.close
	end


	### Check to be sure the Connection hasn't been closed, raising a Mongrel2::ConnectionError
	### if it has.
	def check_closed
		raise Mongrel2::ConnectionError, "operation on closed Connection" if self.closed?
	end


	### Returns +true+ if the connection to the Mongrel2 server has been closed.
	def closed?
		return @closed
	end

end # class Mongrel2::Connection

# vim: set nosta noet ts=4 sw=4:

