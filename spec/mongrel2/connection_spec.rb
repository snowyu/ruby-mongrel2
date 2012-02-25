#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/connection'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Connection do
	include Mongrel2::Config::DSL

	before( :all ) do
		setup_logging( :fatal )
	end

	# Ensure 0MQ never actually gets called
	before( :each ) do
		@ctx = double( "0mq context" )
		Mongrel2.instance_variable_set( :@zmq_ctx, @ctx )

		@conn = Mongrel2::Connection.new( TEST_UUID, TEST_SEND_SPEC, TEST_RECV_SPEC )
	end

	after( :each ) do
		Mongrel2.instance_variable_set( :@zmq_ctx, nil )
	end

	after( :all ) do
		reset_logging()
	end


	it "doesn't connect to the endpoints when it's created" do
		@conn.instance_variable_get( :@request_sock ).should be_nil()
		@conn.instance_variable_get( :@response_sock ).should be_nil()
	end

	it "connects to the endpoints specified on demand" do
		request_sock = double( "request socket" )
		response_sock = double( "response socket" )

		@ctx.should_receive( :socket ).with( ZMQ::PULL ).and_return( request_sock )
		request_sock.should_receive( :setsockopt ).with( ZMQ::LINGER, 0 )
		request_sock.should_receive( :connect ).with( TEST_SEND_SPEC )

		@ctx.should_receive( :socket ).with( ZMQ::PUB ).and_return( response_sock )
		response_sock.should_receive( :setsockopt ).with( ZMQ::LINGER, 0 )
		response_sock.should_receive( :setsockopt ).with( ZMQ::IDENTITY, /^[[:xdigit:]]{40}$/ )
		response_sock.should_receive( :connect ).with( TEST_RECV_SPEC )

		@conn.request_sock.should == request_sock
		@conn.response_sock.should == response_sock
	end

	it "stringifies as a description of the appid and both sockets" do
		@conn.to_s.should == "{#{TEST_UUID}} #{TEST_SEND_SPEC} <-> #{TEST_RECV_SPEC}"
	end

	context "after a connection has been established" do

		before( :each ) do
			@request_sock = double( "request socket", :setsockopt => nil, :connect => nil )
			@response_sock = double( "response socket", :setsockopt => nil, :connect => nil )

			@ctx.stub( :socket ).with( ZMQ::PULL ).and_return( @request_sock )
			@ctx.stub( :socket ).with( ZMQ::PUB ).and_return( @response_sock )

			@conn.connect
		end


		it "closes both of its sockets when closed" do
			@request_sock.should_receive( :close )
			@response_sock.should_receive( :close )

			@conn.close
		end

		it "raises an exception if asked to fetch data after being closed" do
			@request_sock.stub( :close )
			@response_sock.stub( :close )

			@conn.close

			expect {
				@conn.recv
			}.to raise_error( Mongrel2::ConnectionError, /operation on closed connection/i )
		end

		it "doesn't keep its request and response sockets when duped" do
			request_sock2 = double( "request socket", :setsockopt => nil, :connect => nil )
			response_sock2 = double( "response socket", :setsockopt => nil, :connect => nil )
			@ctx.stub( :socket ).with( ZMQ::PULL ).and_return( request_sock2 )
			@ctx.stub( :socket ).with( ZMQ::PUB ).and_return( response_sock2 )

			duplicate = @conn.dup

			duplicate.request_sock.should == request_sock2
			duplicate.response_sock.should == response_sock2
		end

		it "doesn't keep its closed state when duped" do
			@request_sock.should_receive( :close )
			@response_sock.should_receive( :close )

			@conn.close

			duplicate = @conn.dup
			duplicate.should_not be_closed()
		end

		it "can read raw request messages off of the request_sock" do
			@request_sock.should_receive( :recv ).and_return( "the data" )
			@conn.recv.should == "the data"
		end

		it "can read request messages off of the request_sock as Mongrel2::Request objects" do
			msg = make_request()
			@request_sock.should_receive( :recv ).and_return( msg )
			@conn.receive.should be_a( Mongrel2::Request )
		end

		it "can write raw response messages with a TNetString header onto the response_sock" do
			@response_sock.should_receive( :send ).with( "#{TEST_UUID} 1:8, the data" )
			@conn.send( TEST_UUID, 8, "the data" )
		end

		it "can write Mongrel2::Responses to the response_sock" do
			@response_sock.should_receive( :send ).with( "#{TEST_UUID} 1:8, the data" )

			response = Mongrel2::Response.new( TEST_UUID, 8, 'the data' )
			@conn.reply( response )
		end

		it "can write raw response messages to more than one conn_id at the same time" do
			@response_sock.should_receive( :send ).with( "#{TEST_UUID} 15:8 16 44 45 1833, the data" )
			@conn.broadcast( TEST_UUID, [8, 16, 44, 45, 1833], 'the data' )
		end

		it "can write raw response messages to more than one conn_id at the same time" do
			@response_sock.should_receive( :send ).with( "#{TEST_UUID} 15:8 16 44 45 1833, the data" )
			@conn.broadcast( TEST_UUID, [8, 16, 44, 45, 1833], 'the data' )
		end

		it "can tell the connection a request or a response was from to close" do
			@response_sock.should_receive( :send ).with( "#{TEST_UUID} 1:8, " )

			response = Mongrel2::Response.new( TEST_UUID, 8 )
			@conn.reply_close( response )
		end

		it "can broadcast a close to multiple connection IDs" do
			@response_sock.should_receive( :send ).with( "#{TEST_UUID} 15:8 16 44 45 1833, " )
			@conn.broadcast_close( TEST_UUID, [8, 16, 44, 45, 1833] )
		end

	end

end

