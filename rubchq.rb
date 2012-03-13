#!/usr/bin/env ruby

require 'net/http'
require 'uri'

class Basecamp
    attr_accessor :org, :apikey

    def initialize (org, apikey)
        @org, @apikey = org, apikey
    end
end

class Rubchq
    attr_accessor :bchqCreds # Basecamp
    attr_reader   :connector # Net::HTTPSession

    def initialize (creds)
        @bchqCreds = creds
    end

    def getResponse (relative_uri)
        uri = URI('https://' + @bchqCreds.org + '.basecamphq.com/' + relative_uri)

        Net::HTTP.start(uri.host, 80, nil, nil, @bchqCreds.apikey, '') do |http|
            request = Net::HTTP::Get.new uri.request_uri
            response = http.request request
            puts response.inspect
            return response
        end
    end

    def fetchAccountInfo
        getResponse('account.xml')    
    end
end
