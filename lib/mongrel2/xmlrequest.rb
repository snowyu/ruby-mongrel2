#!/usr/bin/ruby

require 'nokogiri'

require 'mongrel2/request' unless defined?( Mongrel2::Request )
require 'mongrel2/mixins'


# The Mongrel2 XML Request class. Instances of this class represent a request for an XML route from
# a Mongrel2 server.
class Mongrel2::XMLRequest < Mongrel2::Request
	include Mongrel2::Loggable

	register_request_type( self, :XML )


	### Parse the body as JSON.
	def initialize( sender_id, conn_id, path, headers, body, raw=nil )
		super
		self.log.debug "Parsing XML request body"
		@data = Nokogiri::XML( body )
	end


	######
	public
	######

	# The parsed request data (a Nokogiri::XML document)
	attr_reader :data


end # class Mongrel2::XMLRequest

# vim: set nosta noet ts=4 sw=4:

