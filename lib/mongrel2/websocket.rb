#!/usr/bin/ruby

require 'mongrel2/request' unless defined?( Mongrel2::Request )
require 'mongrel2/mixins'
require 'mongrel2/constants'


# The Mongrel2 WebSocket namespace module. Contains constants and classes for
# building WebSocket services.
module Mongrel2::WebSocket

	# WebSocket-related header and status constants
	module Constants
		# WebSocket frame header
		#    0                   1                   2                   3
		#    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
		#   +-+-+-+-+-------+-+-------------+-------------------------------+
		#   |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
		#   |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
		#   |N|V|V|V|       |S|             |   (if payload len==126/127)   |
		#   | |1|2|3|       |K|             |                               |
		#   +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
		#   |     Extended payload length continued, if payload len == 127  |
		#   + - - - - - - - - - - - - - - - +-------------------------------+
		#   |                               |Masking-key, if MASK set to 1  |
		#   +-------------------------------+-------------------------------+
		#   | Masking-key (continued)       |          Payload Data         |
		#   +-------------------------------- - - - - - - - - - - - - - - - +
		#   :                     Payload Data continued ...                :
		#   + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
		#   |                     Payload Data continued ...                |
		#   +---------------------------------------------------------------+

		# Masks of the bits of the FLAGS header that corresponds to the FIN and RSV1-3 flags
		FIN_FLAG  = 0b10000000
		RSV1_FLAG = 0b01000000
		RSV2_FLAG = 0b00100000
		RSV3_FLAG = 0b00010000

		# Mask for checking for one or more of the RSV[1-3] flags
		RSV_FLAG_MASK = 0b01110000

		# Mask for picking the opcode out of the flags header
		OPCODE_BITMASK = 0b00001111

		# Mask for testing to see if the frame is a control frame
		OPCODE_CONTROL_MASK = 0b00001000

		# %x0 denotes a continuation frame
		# %x1 denotes a text frame
		# %x2 denotes a binary frame
		# %x3-7 are reserved for further non-control frames
		# %x8 denotes a connection close
		# %x9 denotes a ping
		# %xA denotes a pong
		# %xB-F are reserved for further control frames

		# Opcodes from the flags header
		OPCODE_NAME = Hash.new do |codes,bit|
			raise RangeError, "invalid opcode %d!" % [ bit ] unless bit.between?( 0x0, 0xf )
			codes[ bit ] = :reserved
		end
		OPCODE_NAME[ 0x0 ] = :continuation
		OPCODE_NAME[ 0x1 ] = :text
		OPCODE_NAME[ 0x2 ] = :binary
		OPCODE_NAME[ 0x8 ] = :close
		OPCODE_NAME[ 0x9 ] = :ping
		OPCODE_NAME[ 0xA ] = :pong

		# Opcode bits keyed by name
		OPCODE = OPCODE_NAME.invert

		# Closing status codes (http://tools.ietf.org/html/rfc6455#section-7.4.1)

		# 1000 indicates a normal closure, meaning that the purpose for
		# which the connection was established has been fulfilled.
		CLOSE_NORMAL = 1000

		# 1001 indicates that an endpoint is "going away", such as a server
		# going down or a browser having navigated away from a page.
		CLOSE_GOING_AWAY = 1001

		# 1002 indicates that an endpoint is terminating the connection due
		# to a protocol error.
		CLOSE_PROTOCOL_ERROR = 1002

		# 1003 indicates that an endpoint is terminating the connection
		# because it has received a type of data it cannot accept (e.g., an
		# endpoint that understands only text data MAY send this if it
		# receives a binary message).
		CLOSE_BAD_DATA_TYPE = 1003

		# Reserved.  The specific meaning might be defined in the future.
		CLOSE_RESERVED = 1004

		# 1005 is a reserved value and MUST NOT be set as a status code in a
		# Close control frame by an endpoint.  It is designated for use in
		# applications expecting a status code to indicate that no status
		# code was actually present.
		CLOSE_MISSING_STATUS = 1005

		# 1006 is a reserved value and MUST NOT be set as a status code in a
		# Close control frame by an endpoint.  It is designated for use in
		# applications expecting a status code to indicate that the
		# connection was closed abnormally, e.g., without sending or
		# receiving a Close control frame.
		CLOSE_ABNORMAL_STATUS = 1006

		# 1007 indicates that an endpoint is terminating the connection
		# because it has received data within a message that was not
		# consistent with the type of the message (e.g., non-UTF-8 [RFC3629]
		# data within a text message).
		CLOSE_BAD_DATA = 1007

		# 1008 indicates that an endpoint is terminating the connection
		# because it has received a message that violates its policy.  This
		# is a generic status code that can be returned when there is no
		# other more suitable status code (e.g., 1003 or 1009) or if there
		# is a need to hide specific details about the policy.
		CLOSE_POLICY_VIOLATION = 1008

		# 1009 indicates that an endpoint is terminating the connection
		# because it has received a message that is too big for it to
		# process.
		CLOSE_MESSAGE_TOO_LARGE = 1009

		# 1010 indicates that an endpoint (client) is terminating the
		# connection because it has expected the server to negotiate one or
		# more extension, but the server didn't return them in the response
		# message of the WebSocket handshake.  The list of extensions that
		# are needed SHOULD appear in the /reason/ part of the Close frame.
		# Note that this status code is not used by the server, because it
		# can fail the WebSocket handshake instead.
		CLOSE_MISSING_EXTENSION = 1010

		# 1011 indicates that a server is terminating the connection because
		# it encountered an unexpected condition that prevented it from
		# fulfilling the request.
		CLOSE_EXCEPTION = 1011

		# 1015 is a reserved value and MUST NOT be set as a status code in a
		# Close control frame by an endpoint.  It is designated for use in
		# applications expecting a status code to indicate that the
		# connection was closed due to a failure to perform a TLS handshake
		# (e.g., the server certificate can't be verified).
		CLOSE_TLS_ERROR = 1015

		# Human-readable messages for each closing status code.
		CLOSING_STATUS_DESC = {
			CLOSE_NORMAL            => 'Session closed normally.',
			CLOSE_GOING_AWAY        => 'Endpoint going away.',
			CLOSE_PROTOCOL_ERROR    => 'Protocol error.',
			CLOSE_BAD_DATA_TYPE     => 'Unhandled data type.',
			CLOSE_RESERVED          => 'Reserved for future use.',
			CLOSE_MISSING_STATUS    => 'No status code was present.',
			CLOSE_ABNORMAL_STATUS   => 'Abnormal close.',
			CLOSE_BAD_DATA          => 'Bad or malformed data.',
			CLOSE_POLICY_VIOLATION  => 'Policy violation.',
			CLOSE_MESSAGE_TOO_LARGE => 'Message too large for endpoint.',
			CLOSE_MISSING_EXTENSION => 'Missing extension.',
			CLOSE_EXCEPTION         => 'Unexpected condition/exception.',
			CLOSE_TLS_ERROR         => 'TLS handshake failure.',
		}

	end # module WebSocket
	include Constants

	# Base exception class for WebSocket-related errors
	class Error < ::RuntimeError; end

	# Exception raised when a frame is malformed, doesn't parse, or is otherwise invalid.
	class FrameError < Mongrel2::WebSocket::Error; end


	# WebSocket frame class; this is used for both requests and responses in
	# WebSocket services.
	class Frame < Mongrel2::Request
		include Mongrel2::WebSocket::Constants

		# The default frame header flags: FIN + CLOSE
		DEFAULT_FLAGS = FIN_FLAG | OPCODE[:close]


		# Set this class as the one that will handle WEBSOCKET requests
		register_request_type( self, :WEBSOCKET )


		### Override the type of response returned by this request type. Since
		### WebSocket connections are symmetrical, responses are just new
		### WebSocketFrames with the same Mongrel2 sender and connection IDs.
		def self::response_class
			return self
		end


		### Create a response frame from the given request +frame+.
		def self::from_request( frame )
			Mongrel2.log.debug "Creating a %p response to request %p" % [ self, frame ]
			response = new( frame.sender_id, frame.conn_id, frame.path )
			response.request_frame = frame

			return response
		end


		### Define accessors for the flag of the specified +name+ and +bit+.
		def self::attr_flag( name, bitmask )
			define_method( "#{name}?" ) do
				(self.flags & bitmask).nonzero?
			end
			define_method( "#{name}=" ) do |newvalue|
				if newvalue
					self.flags |= bitmask
				else
					self.flags ^= ( self.flags & bitmask )
				end
			end
		end



		#################################################################
		###	I N S T A N C E   M E T H O D S
		#################################################################

		### Override the constructor to add Integer flags extracted from the FLAGS header.
		def initialize( sender_id, conn_id, path, headers={}, payload='', raw=nil )
			super

			@flags = Integer( self.headers.flags || DEFAULT_FLAGS )
			@request_frame = nil
		end


		######
		public
		######

		# The payload data
		attr_accessor :body
		alias_method :payload, :body
		alias_method :payload=, :body=


		# The frame's header flags as an Integer
		attr_accessor :flags

		# The frame that this one is a response to
		attr_accessor :request_frame

		### Returns +true+ if the request's FIN flag is set. This flag indicates that
		### this is the final fragment in a message.  The first fragment MAY also be
		### the final fragment.
		attr_flag :fin, FIN_FLAG

		### Returns +true+ if the request's RSV1 flag is set. RSV1-3 MUST be 0 unless
		### an extension is negotiated that defines meanings for non-zero values.  If
		### a nonzero value is received and none of the negotiated extensions defines
		### the meaning of such a nonzero value, the receiving endpoint MUST _fail the
		### WebSocket connection_.
		attr_flag :rsv1, RSV1_FLAG
		attr_flag :rsv2, RSV2_FLAG
		attr_flag :rsv3, RSV3_FLAG


		### Returns true if one or more of the RSV1-3 bits is set.
		def has_rsv_flags?
			return ( self.flags & RSV_FLAG_MASK ).nonzero?
		end


		### Returns the name of the frame's opcode as a Symbol. The #numeric_opcode method
		### returns the numeric one.
		def opcode
			return OPCODE_NAME[ self.numeric_opcode ]
		end


		### Return the numeric opcode of the frame.
		def numeric_opcode
			return self.flags & OPCODE_BITMASK
		end


		### Set the frame's opcode to +code+, which should be either a numeric opcode or
		### its equivalent name (i.e., :continuation, :text, :binary, :close, :ping, :pong)
		def opcode=( code )
			opcode = OPCODE[ code.to_sym ] or
				raise ArgumentError, "unknown opcode %p" % [ code ]

			self.flags ^= ( self.flags & OPCODE_BITMASK )
			self.flags |= opcode
		end


		### Returns +true+ if the request is a WebSocket control frame.
		def control?
			return ( self.flags & OPCODE_CONTROL_MASK ).nonzero?
		end


		### Append the given +object+ to the payload. Returns the Frame for
		### chaining.
		def <<( object )
			self.payload << object
			return self
		end


		### Write the given +objects+ to the payload, calling #to_s on each one.
		def puts( *objects )
			objects.each do |obj|
				self << obj.to_s.chomp << $/
			end
		end


		### Overwrite the frame's payload with a status message based on
		### +statuscode+.
		def set_status( statuscode )
			self.log.warn "Unknown status code %d" unless CLOSING_STATUS_DESC.key?( statuscode )
			status_msg = "%d %s" % [ statuscode, CLOSING_STATUS_DESC[statuscode] ]

			self.payload.replace( status_msg )
		end


		### Stringify into a response suitable for sending to the client.
		def to_s
			data = self.payload.to_s

			# Make sure the outgoing payload is UTF-8, except in the case of a
			# binary frame.
			if self.opcode != :binary && data.encoding != Encoding::UTF_8
				self.log.debug "Transcoding %s payload data to UTF-8" % [ data.encoding.name ]
				data.encode!( Encoding::UTF_8 )
			end

			# Control frames: [RFC6455, section-5.5]: All control frames MUST
			# have a payload length of 125 bytes or less and MUST NOT be
			# fragmented.
			self.check_control_frame( data ) if self.control?

			data.force_encoding( Encoding::ASCII_8BIT )
			return [
				self.make_header( data ),
				data
			].join
		end


		### Return an Enumerator for the bytes of the raw frame as it appears
		### on the wire.
		def bytes
			return self.to_s.bytes
		end


		### Apply flag bits and opcodes: (:fin, :rsv1, :rsv2, :rsv3, :continuation,
		### :text, :binary, :close, :ping, :pong) to the frame.
		###
		###   # Transform the frame into a CLOSE frame and set its FIN flag
		###   frame.set_flags( :fin, :close )
		###
		def set_flags( *flag_symbols )
			flag_symbols.flatten!
			flag_symbols.compact!

			self.log.debug "Setting flags for symbols: %p" % [ flag_symbols ]

			flag_symbols.each do |flag|
				case flag
				when :fin, :rsv1, :rsv2, :rsv3
					self.__send__( "#{flag}=", true )
				when :continuation, :text, :binary, :close, :ping, :pong
					self.opcode = flag
				when Integer
					self.log.debug "  setting Integer flags directly: 0b%08b" % [ integer ]
					self.flags |= flag
				else
					raise ArgumentError, "Don't know what the %p flag is." % [ flag ]
				end
			end
		end


		### Create a Mongrel2::Response that will respond to the same server/connection as
		### the receiver. If you wish your specialized Request class to have a corresponding
		### response type, you can override the Mongrel2::Request.response_class method
		### to achieve that.
		def response( *flags )
			unless @response
				@response = super()

				self.log.debug "Setting up response %p with symmetrical flags" % [ @response ]
				if self.opcode == :ping
					@response.opcode = :pong
					@response.payload = self.payload
				else
					@response.opcode = self.opcode
				end

				unless flags.empty?
					self.log.debug "  applying custom flags: %p" % [ flags ]
					@response.set_flags( *flags )
				end

				self.log.debug "  response is now: %p" % [ @response ]
			end

			return @response
		end


		#########
		protected
		#########

		### Return the details to include in the contents of the #inspected object.
		def inspect_details
			return %Q{FIN:%d RSV1:%d RSV2:%d RSV3:%d OPCODE:%s (0x%x) -- %0.2fK body} % [
				self.fin?  ? 1 : 0,
				self.rsv1? ? 1 : 0,
				self.rsv2? ? 1 : 0,
				self.rsv3? ? 1 : 0,
				self.opcode,
				self.numeric_opcode,
				(self.payload.bytesize / 1024.0),
			]
		end


		### Make a WebSocket header for the receiving frame and return it.
		def make_header( data )
			header = ''.force_encoding( Encoding::ASCII_8BIT )
			length = data.bytesize
			self.log.debug "Making wire protocol header for payload of %d bytes" % [ length ]

			# Pack the frame according to its size
			if length >= 2**16
				self.log.debug "  giant size, using 8-byte (64-bit int) length field"
				header = [ self.flags, 127, length ].pack( 'c2q>' )
			elsif length > 125
				self.log.debug "  big size, using 2-byte (16-bit int) length field"
				header = [ self.flags, 126, length ].pack( 'c2n' )
			else
				self.log.debug "  small size, using payload length field"
				header = [ self.flags, length ].pack( 'c2' )
			end

			self.log.debug "  header is: %s" % [ header.unpack('h*').first.scan(/../).join(' ') ]
			return header
		end


		### Sanity-check control frame +data+, raising a Mongrel2::WebSocket::FrameError
		### if there's a problem.
		def check_control_frame( data )
			self.log.debug "Checking for problems with a control frame:"

			self.log.debug "  payload bytesize should be < 125 bytes"
			if data.bytesize > 125
				self.log.error "Payload of control frame exceeds 125 bytes (%d)" % [ data.bytesize ]
				raise Mongrel2::WebSocket::FrameError,
					"payload of control frame cannot exceed 125 bytes"
			end

			self.log.debug "  should not be fragmented"
			unless self.fin?
				self.log.error "Control frame fragmented (FIN is unset)"
				raise Mongrel2::WebSocket::FrameError,
					"control frame is fragmented (no FIN flag set)"
			end
		end

	end # class Frame

end # module Mongrel2::WebSocket

# vim: set nosta noet ts=4 sw=4:

