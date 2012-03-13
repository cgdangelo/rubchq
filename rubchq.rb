#!/usr/bin/env ruby

require 'net/http'
require 'net/https'
require 'uri'
require 'rexml/document'

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
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth @bchqCreds.apikey, ''

        response = http.request(request)

        response
    end

    # Accounts

    def fetchAccountInfo (parse = true)
        rawXml = getResponse('account.xml')

        if parse 
            parseAccountInfo(rawXml.body)
        else
            rawXml
        end
    end


    # Projects

    def fetchProjectList (parse = true)
        rawXml = getResponse('projects.xml')
        
        if parse 
            parseProjectList(rawXml.body)
        else
            rawXml
        end
    end

    def parseProjectList (data)
        xmlDoc = REXML::Document.new(data)
        parsedData = []
        projectData = {}

        xmlDoc.elements.each('projects/project/*') do |element|
            projectData[element.name] = element.text
            parsedData[element.parent.elements['id'].text.to_i] = projectData
        end

        parsedData
    end
end
