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

		req.body.should == TEST_JSON_BODY
	end


end

