#!/usr/bin/env ruby

require 'pathname'
require 'logger'
require 'mongrel2/config'
require 'mongrel2/handler'

# A handler that just dumps the request it gets from Mongrel2
class WebSocketEchoServer < Mongrel2::Handler

	### Add some instance variables.
	def initialize( * )
		super
		@connections = Hash.new {|h,sender_id| h[sender_id] = {} }
	end


	######
	public
	######

	### Log disconnections
	def handle_disconnect( request )
		self.log.info "Client %d: disconnect." % [ request.conn_id ]
	end


	### Drop non-websocket requests.
	def handle( request )
		self.log.info "Regular HTTP request (%s): closing channel." % [ request ]
		self.conn.reply_close( request )
		return nil
	end


	### Handle websocket frames
	def handle_websocket( frame )
		if frame.has_rsv_flags?
			res = frame.response( :close )
			res.set_close_status( WebSocket::CLOSE_PROTOCOL_ERROR )
			return res
		end

		handler = self.method( "handle_%s_frame" % [frame.opcode] )
		return handler.call( frame )
	end


	### Handle TEXT, BINARY, and CONTINUATION frames by replying with an echo of the
	### same data. Fragmented frames get echoed back as-is without any reassembly.
	def handle_text_frame( frame )
		self.log.info "Echoing data frame: %p" % [ frame ]

		@connections[ frame.sender_id ][ frame.conn_id ] = Time.now
		response = frame.response
		response.fin = frame.fin?
		response.payload = frame.payload

		return response
	end
	alias_method :handle_binary_frame, :handle_text_frame
	alias_method :handle_continuation_frame, :handle_text_frame


	### Handle a CLOSE frame
	def handle_close_frame( frame )
		# There will still be a connection slot if this close originated with
		# the client. In that case, reply with the ACK CLOSE frame
		time = @connections[ frame.sender_id ].delete( frame.conn_id )
		self.conn.reply( frame.response(:close) ) if time

		self.conn.reply_close( frame )
		return nil
	end


	### Handle a PING frame
	def handle_ping_frame( frame )
		# A PING's response is a PONG with the same payload.
		@connections[ frame.sender_id ][ frame.conn_id ] = Time.now
		return frame.response
	end


	### Handle a PONG frame
	### TODO: Ignored for now; perhaps later we can ping to test
	###       connections for alive-ness?
	def handle_pong_frame( frame )
		self.log.info "Ignoring unsolicited PONG frame."
	end

end # class RequestDumper

Mongrel2.log.level = $DEBUG ? Logger::DEBUG : Logger::INFO

# Point to the config database, which will cause the handler to use
# its ID to look up its own socket info.
Mongrel2::Config.configure( :configdb => 'examples.sqlite' )
WebSocketEchoServer.run( 'ws-echo' )

