# Copyright (c) 2012 DiUS Computing Pty Ltd

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial 
# portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require 'base64'
require 'httparty'
require 'openssl'
require 'ostruct'
require 'erb'
require 'rexml/document'

include REXML

AWS_ACCESS_KEY = ENV['AWS_ACCESS_KEY']
AWS_SECRET_KEY = ENV['AWS_SECRET_KEY']
ROUTE53_HOST = "route53.amazonaws.com"
RRSET_TEMPLATE = File.expand_path("../route53_rrset.erb", __FILE__)
DEFAULT_TTL = 300
RRSET_XPATH = "ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet"
RR_XPATH = "ResourceRecords/ResourceRecord"

class ErbStruct < OpenStruct
  def get_binding
    binding
  end
end

module Route53

  def self.base_uri zone_id
    "https://#{ROUTE53_HOST}/2012-02-29/hostedzone/#{zone_id}"
  end

  def self.current_date
    response = HTTParty.get "https://#{ROUTE53_HOST}/date"
    response.headers['date']
  end

  def self.sign text, key
    digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, text)
    Base64.encode64(digest)
  end

  def self.headers
    date = current_date
    request_auth_header = "AWS3-HTTPS AWSAccessKeyId=#{AWS_ACCESS_KEY}"
    request_auth_header += ",Algorithm=HmacSHA256,Signature=#{sign(date, AWS_SECRET_KEY)}"

    {
      "Host" => ROUTE53_HOST,
      "Date" => date,
      "Content-Type" => "text/xml; charset=UTF-8",
      "X-Amzn-Authorization" => request_auth_header
    }
  end

  def self.list_rrsets zone_id, name
    response = HTTParty.get("#{base_uri(zone_id)}/rrset?name=#{name}", :headers => headers)
    response_dom = Document.new response.body
    return response_dom.elements.collect(RRSET_XPATH) do |recordset_element|
      {
          :name => recordset_element.elements["Name"].text,
          :type => recordset_element.elements["Type"].text,
          :values => recordset_element.elements.collect(RR_XPATH) { |record_element| record_element.elements["Value"].text }
      }
    end
  end

  def self.create_rrset zone_id, name, type, value
    modify_rrset "CREATE", zone_id, name, type, value
  end

  def self.delete_rrset zone_id, name, type, value
    modify_rrset "DELETE", zone_id, name, type, value
  end

  def self.modify_rrset action, zone_id, name, type, value
    payload_data = ErbStruct.new(
        {:action => action, :name => name, :type => type, :ttl => DEFAULT_TTL, :value => value}
    )
    payload = ERB.new(File.new(RRSET_TEMPLATE).read).result(payload_data.get_binding)

    response = HTTParty.post("#{base_uri(zone_id)}/rrset", :body => payload, :headers => headers)

    if response.code != 200
      response_dom = Document.new response.body
      error_code = response_dom.root.elements["Error/Code"].text
      error_message = response_dom.root.elements["Error/Message"].text
      raise "Failed to create recordset: (#{error_code}) #{error_message}"
    end
  end


end