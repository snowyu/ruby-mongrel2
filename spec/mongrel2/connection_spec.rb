#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/connection'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Connection do

	TEST_REQ_ADDR = 'tcp://127.0.0.1:9998'
	TEST_RES_ADDR = 'tcp://127.0.0.1:9999'


	# it "connects to the endpoints specified when it's created" do
	# 	conn = Mongrel2::Connection.new( TEST_UUID, TEST_REQ_ADDR, TEST_RES_ADDR )
	# 	conn.request_sock.should be_a( ZMQ::Socket )
	# 	conn.response_sock.should be_a( ZMQ::Socket )
	# end

end

