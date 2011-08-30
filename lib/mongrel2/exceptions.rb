#!/usr/bin/env ruby

#--
module Mongrel2

	# An exception class raised from a Mongrel2::Request when
	# a problem is encountered while parsing raw request data.
	class ParseError < ::RuntimeError; end

	# An exception class raised when an attempt is made to use a
	# Mongrel2::Connection after it has been closed.
	class ConnectionError < ::RuntimeError; end

end # module Mongrel2


# vim: set noet nosta sw=4 ts=4 :
