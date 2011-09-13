#!/usr/bin/env rspec -cfd -b

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'

require 'spec/lib/helpers'

require 'logger'
require 'mongrel2'


describe Mongrel2 do

	describe "version methods" do
		it "returns a version string if asked" do
			Mongrel2.version_string.should =~ /\w+ [\d.]+/
		end


		it "returns a version string with a build number if asked" do
			Mongrel2.version_string(true).should =~ /\w+ [\d.]+ \(build [[:xdigit:]]+\)/
		end
	end

end

