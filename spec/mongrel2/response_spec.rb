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
require 'mongrel2/response'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Response do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "can create a new instance from a Request" do
		req = Mongrel2::Request.new( TEST_UUID, 8, '/path', {}, '' )
		response = Mongrel2::Response.from_request( req )

		response.should be_a( Mongrel2::Response )
		response.sender_id.should == req.sender_id
		response.conn_id.should == req.conn_id
	end


end

