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
require 'mongrel2/model'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Model do

	it "has a factory method for creating derivative classes" do
		model_class = Mongrel2::Model( :hookers )
		model_class.should < Mongrel2::Model
		model_class.dataset.first_source.should == :hookers
	end

end

