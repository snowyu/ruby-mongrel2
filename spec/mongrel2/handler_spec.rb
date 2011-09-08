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
require 'mongrel2/config'
require 'mongrel2/handler'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Handler do

	before( :all ) do
		setup_logging( :fatal )
		Mongrel2::Config.configure( :configdb => ':memory:' )
		Mongrel2::Config.init_database!

		Mongrel2::Config::Handler.create( HANDLER_CONFIG )
	end

	before( :each ) do
		@ctx = double( "0mq context" )
		@request_sock = double( "request socket", :connect => nil )
		@response_sock = double( "response socket", :setsockopt => nil, :connect => nil )

		@ctx.stub( :socket ).with( ZMQ::PULL ).and_return( @request_sock )
		@ctx.stub( :socket ).with( ZMQ::PUB ).and_return( @response_sock )

		Mongrel2.instance_variable_set( :@zmq_ctx, @ctx )
	end

	after( :each ) do
		Mongrel2.instance_variable_set( :@zmq_ctx, nil )
	end

	after( :all ) do
		reset_logging()
	end


	HANDLER_CONFIG = {
		:send_spec => TEST_SEND_SPEC,
		:send_ident => TEST_UUID,
		:recv_spec => TEST_RECV_SPEC,
	}


	it "can configure its Connection by looking up its own config" do
		hclass = Class.new( Mongrel2::Handler )
		hclass.connection_info_for( TEST_UUID ).should == [ TEST_SEND_SPEC, TEST_RECV_SPEC ]
	end


	it "raises an exception if no handler with its appid exists in the config DB" do
		Mongrel2::Handler.connection_info_for( TEST_UUID ).should == [ TEST_SEND_SPEC, TEST_RECV_SPEC ]
	end


	it "has a convenience method for instantiating and running a Handler from the config DB" do
		handler_class = Class.new( Mongrel2::Handler ) do
			def initialize( * )
				@requests = []
				super
			end

			attr_reader :requests

			# Overridden to accept one request and shut down
			def dispatch_request( request )
				@requests << request
				self.shutdown
			end
		end
		req = make_request()
		@request_sock.should_receive( :recv ).and_return( req )
		@request_sock.should_receive( :close )
		@response_sock.should_receive( :close )

		res = handler_class.run( TEST_UUID )

		res.requests.should have( 1 ).member
		res.requests.first.should be_a( Mongrel2::HTTPRequest )
	end

end

