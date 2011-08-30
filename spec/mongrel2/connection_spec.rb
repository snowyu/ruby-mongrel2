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
	include Mongrel2::Config::DSL

	TEST_SERVER_UUID = '965A7196-99BC-46FA-945B-3478AE92BFB5'
	TEST_REQ_ADDR    = 'tcp://127.0.0.1:9998'
	TEST_RES_ADDR    = 'tcp://127.0.0.1:9999'
	TEST_REQ_SPEC    = '11F31222-30C1-4977-9D13-17E955665F44'


	before( :all ) do
		setup_logging( :info )
		@pid = setup_testing_mongrel_instance( TEST_SERVER_UUID, TEST_REQ_ADDR, TEST_REQ_SPEC,
		                                       TEST_RES_ADDR )
	end

	before( :each ) do
		@conn = Mongrel2::Connection.new( TEST_UUID, TEST_REQ_ADDR, TEST_RES_ADDR )
	end

	after( :each ) do
		@conn.close
	end

	after( :all ) do
		teardown_testing_mongrel_instance( @pid )

		Mongrel2.log.info "Closing the 0mq context."
		Mongrel2.zmq_context.close
		Mongrel2.instance_variable_set( :@zmq_ctx, nil )

		reset_logging()
	end


	it "connects to the endpoints specified when it's created" do
		@conn.request_sock.should be_a( ZMQ::Socket )
		@conn.response_sock.should be_a( ZMQ::Socket )
	end

	it "raises an exception if asked to fetch data after being closed" do
		@conn.close
		expect {
			@conn.recv
		}.to raise_error( Mongrel2::ConnectionError, /operation on closed connection/i )
	end

end

