#!/usr/bin/env ruby

#--
module Mongrel2

	# A base exception class.
	class Exception < ::RuntimeError; end

	# An exception class raised from a Mongrel2::Request when
	# a problem is encountered while parsing raw request data.
	class ParseError < Mongrel2::Exception; end

	# An exception class raised from a Mongrel2::Request when
	# the raw request headers contain an unhandled METHOD.
	class UnhandledMethodError < Mongrel2::Exception

		### Set the +method_name+ that was unhandled.
		def initialize( method_name, *args )
			@method_name = method_name
			super( "Unhandled method %p" % [ method_name ], *args )
		end

		# The METHOD that was unhandled
		attr_reader :method_name

	end # class UnhandledMethodError

	# An exception class raised when an attempt is made to use a
	# Mongrel2::Connection after it has been closed.
	class ConnectionError < Mongrel2::Exception; end

	# An exception type raised when an operation requires that a configuration
	# database be configured but none was; if it's configured but doesn't
	# exist; or if it doesn't contain the information requested.
	class ConfigError < Mongrel2::Exception; end

	# An exception type raised by a response if it can't generate a valid response
	# document
	class ResponseError < Mongrel2::Exception; end

	# An exception type raised by Mongrel2::Control requests if they result in
	# an error response.
	class ControlError < Mongrel2::Exception

		### Set the error +code+ in addition to the +message+.
		def initialize( code, message )
			@code = code.to_sym
			super( message )
		end

		# The code of the particular kind of control error (a Symbol)
		attr_reader :code

	end # class ControlError

end # module Mongrel2


# vim: set noet nosta sw=4 ts=4 :
