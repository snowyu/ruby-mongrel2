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

describe Mongrel2::Constants do

	it "defines a default configuration URI" do
		Mongrel2::Constants.constants.map( &:to_sym ).should include( :DEFAULT_CONFIG_URI )
	end

end

