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

		message = make_request()
		req = Mongrel2::Request.parse( message )

		req.should be_a( Mongrel2::Request )
		req.sender_id.should == TEST_UUID
		req.conn_id.should == TEST_ID

		req.headers.should be_a( Mongrel2::Table )
		req.headers['Host'].should == TEST_HEADERS['host']
	end

	it "can parse a request message with TNetstring headers" do

		message = make_tn_request()
		req = Mongrel2::Request.parse( message )

		req.should be_a( Mongrel2::Request )
		req.sender_id.should == TEST_UUID
		req.conn_id.should == TEST_ID

		req.headers.should be_a( Mongrel2::Table )
		req.headers.host.should == TEST_HEADERS['host']
	end

	it "can parse a request message with a JSON body" do

		message = make_json_request()
		req = Mongrel2::Request.parse( message )

		req.should be_a( Mongrel2::JSONRequest )
		req.sender_id.should == TEST_UUID
		req.conn_id.should == TEST_ID

		req.headers.should be_a( Mongrel2::Table )
		req.headers.path.should == TEST_JSON_PATH

		req.data.should == TEST_JSON_BODY
	end

	it "raises an UnhandledMethodError with the name of the method for METHOD verbs that " +
	   "don't look like HTTP ones" do

		message = make_request( :headers => {'METHOD' => '!DIVULGE'} )
		expect {
			Mongrel2::Request.parse( message )
		}.to raise_error( Mongrel2::UnhandledMethodError, /!DIVULGE/ )
	end

	it "knows what kind of response it should return" do
		Mongrel2::Request.response_class.should == Mongrel2::Response
	end


	describe "instances" do

		before( :each ) do
			message = make_json_request() # HTTPRequest overrides the #response method
			@req = Mongrel2::Request.parse( message )
		end

		it "can return an appropriate response instance for themselves" do
			result = @req.response
			result.should be_a( Mongrel2::Response )
			result.sender_id.should == @req.sender_id
			result.conn_id.should == @req.conn_id
		end

		it "remembers its response if it's already made one" do
			@req.response.should equal( @req.response )
		end

	end


	describe "framework support" do

		before( :all ) do
			@oldtypes = Mongrel2::Request.request_types
			@original_default_proc = Mongrel2::Request.request_types.default_proc
		end

		before( :each ) do
			Mongrel2::Request.request_types.default_proc = @original_default_proc
			Mongrel2::Request.request_types.clear
		end

		after( :all ) do
			Mongrel2::Request.request_types.default_proc = @original_default_proc
			Mongrel2::Request.request_types.replace( @oldtypes )
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

