#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'
require 'tnetstring'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/request'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Request do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "can parse a request message" do

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		message = "%s %d %s %s%s" % [
			TEST_UUID,
			TEST_ID,
			TEST_PATH,
			TEST_HEADERS_JSONSTRING,
			TEST_BODY_TNETSTRING,
		]

		req = Mongrel2::Request.parse( message )

		req.should be_a( Mongrel2::Request )
		req.sender_id.should == TEST_UUID
		req.conn_id.should == TEST_ID

		req.headers.should be_a( Mongrel2::Table )
		req.headers['Host'].should == TEST_HEADERS['host']
	end

	it "can parse a request message with TNetstring headers" do

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		message = "%s %d %s %s%s" % [
			TEST_UUID,
			TEST_ID,
			TEST_PATH,
			TEST_HEADERS_TNETSTRING,
			TEST_BODY_TNETSTRING,
		]

		req = Mongrel2::Request.parse( message )

		req.should be_a( Mongrel2::Request )
		req.sender_id.should == TEST_UUID
		req.conn_id.should == TEST_ID

		req.headers.should be_a( Mongrel2::Table )
		req.headers.host.should == TEST_HEADERS['host']
	end

	it "can parse a request message with a JSON body" do

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		message = "%s %d %s %s%s" % [
			TEST_UUID,
			TEST_ID,
			TEST_JSON_PATH,
			TEST_JSON_HEADERS_JSONSTRING,
			TEST_JSON_BODY_TNETSTRING,
		]

		req = Mongrel2::Request.parse( message )

		req.should be_a( Mongrel2::Request )
		req.sender_id.should == TEST_UUID
		req.conn_id.should == TEST_ID

		req.headers.should be_a( Mongrel2::Table )
		req.headers.path.should == TEST_JSON_BODY_HEADERS['PATH']

		req.body.should == TEST_JSON_BODY_STRING
	end


	describe "instances" do

		before( :each ) do
			# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
			message = "%s %d %s %s%s" % [
				TEST_UUID,
				TEST_ID,
				TEST_PATH,
				TEST_HEADERS_JSONSTRING,
				TEST_BODY_TNETSTRING,
			]

			@req = Mongrel2::Request.parse( message )
		end

		it "can return a Mongrel2::Response that is pre-configured to response to themselves" do
			result = @req.response
			result.should be_a( Mongrel2::Response )
			result.sender_id.should == @req.sender_id
			result.conn_id.should == @req.conn_id
		end

	end


	describe "framework support" do

		before( :all ) do
			@original_default_proc = Mongrel2::Request.request_types.default_proc
		end

		before( :each ) do
			Mongrel2::Request.request_types.default_proc = @original_default_proc
			Mongrel2::Request.request_types.clear
		end

		after( :all ) do
			Mongrel2::Request.request_types.default_proc = @original_default_proc
			Mongrel2::Request.request_types.clear
		end


		it "includes a mechanism for overriding the default Request subclass" do
			subclass = Class.new( Mongrel2::Request ) do
				register_request_type self, :__default
			end

			Mongrel2::Request.subclass_for_method( 'GET' ).should == subclass
			Mongrel2::Request.subclass_for_method( 'POST' ).should == subclass
			Mongrel2::Request.subclass_for_method( 'JSON' ).should == subclass
		end

		it "includes a mechanism for overriding the Request subclass for a particular request " +
		   "method" do
			subclass = Class.new( Mongrel2::Request ) do
				register_request_type self, :GET
			end

			Mongrel2::Request.subclass_for_method( 'GET' ).should == subclass
			Mongrel2::Request.subclass_for_method( 'POST' ).should_not == subclass
			Mongrel2::Request.subclass_for_method( 'JSON' ).should_not == subclass
		end

		it "clears any cached method -> subclass lookups when the default subclass changes" do
			Mongrel2::Request.subclass_for_method( 'OPTIONS' ) # cache OPTIONS -> Mongrel2::Request

			subclass = Class.new( Mongrel2::Request ) do
				register_request_type self, :__default
			end

			Mongrel2::Request.subclass_for_method( 'OPTIONS' ).should == subclass
		end

	end

end

