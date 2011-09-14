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
require 'mongrel2/httprequest'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::HTTPRequest do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		headers = normalize_headers( {} )
		@req = Mongrel2::HTTPRequest.new( TEST_UUID, 8817, '/test', headers, '' )
	end

	after( :all ) do
		reset_logging()
	end


	it "can create an HTTPResponse for itself" do
		result = @req.response
		result.should be_a( Mongrel2::HTTPResponse )
		result.sender_id.should == @req.sender_id
		result.conn_id.should == @req.conn_id
	end

	it "remembers its corresponding HTTPResponse if it's created it already" do
		result = @req.response
		result.should be_a( Mongrel2::HTTPResponse )
		result.sender_id.should == @req.sender_id
		result.conn_id.should == @req.conn_id
	end

	it "knows that its connection isn't persistent if it's an HTTP/1.0 request" do
		@req.headers.version = 'HTTP/1.0'
		@req.should_not be_keepalive()
	end

	it "knows that its connection isn't persistent if has a 'close' token in its Connection header" do
		@req.headers.version = 'HTTP/1.1'
		@req.headers[ :connection ] = 'violent, close'
		@req.should_not be_keepalive()
	end

	it "knows that its connection could be persistent if doesn't have a Connection header, " +
	   "and it's an HTTP/1.1 request" do
		@req.headers.version = 'HTTP/1.1'
		@req.headers.delete( :connection )
		@req.should be_keepalive()
	end

	it "knows that its connection is persistent if has a Connection header without a 'close' " +
	   "token and it's an HTTP/1.1 request" do
		@req.headers.version = 'HTTP/1.1'
		@req.headers.connection = 'keep-alive'
		@req.should be_keepalive()
	end

end

