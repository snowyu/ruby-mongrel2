#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Directory (Dir) configuration class
class Mongrel2::Config::Directory < Mongrel2::Config( :directory )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE directory (id INTEGER PRIMARY KEY,
	#    base TEXT,
	#    index_file TEXT,
	#    default_ctype TEXT,
	#    cache_ttl INTEGER DEFAULT 0);

	### Sequel validation callback: add errors if the record is invalid.
	def validate
		self.validate_base
		self.validate_index_file
		self.validate_default_ctype
		self.validate_cache_ttl
	end


	#########
	protected
	#########

	### Validate the 'base' directory which will be served.
	def validate_base
		self.validates_presence( :base, :message => "must not be nil" )
	end


	### Validate the 'index_file' attribute.
	def validate_index_file
	end


	def validate_default_ctype
	end


	def validate_cache_ttl
	end




end # class Mongrel2::Config::Directory

