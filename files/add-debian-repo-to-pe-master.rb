#!/opt/puppetlabs/puppet/bin/ruby

# GROUPID=$(curl -X GET -H 'Content-Type: application/json' --cert $(puppet config print hostcert) --key $(puppet config print hostprivkey) --cacert $(puppet config print localcacert) 'https://puppet:4433/classifier-api/v1/groups?inherited=true' | jq '.[] | select(.name == "PE Master") | .id')     
# CLASSID=$(curl -X GET -H 'Content-Type: application/json' --cert $(puppet config print hostcert) --key $(puppet config print hostprivkey) --cacert $(puppet config print localcacert) 'https://puppet:4433/classifier-api/v1/classes' | jq '.[] | select(.name == "PE Master") | .id')                   

require 'net/http'
require 'openssl'
require 'json'
require 'pp'

klass = 'pe_repo::platform::debian_9_amd64'
group = 'PE Master'
group_id = ''
jsongroup = []

cert = `puppet config print hostcert`.strip
key = `puppet config print hostprivkey`.strip
cacert = `puppet config print localcacert`.strip

uri = URI('https://puppet:4433/classifier-api/v1/groups?inherited=true')

Net::HTTP.start(
  uri.host,
  uri.port,
  :use_ssl => uri.scheme == 'https',
  :verify_mode => OpenSSL::SSL::VERIFY_NONE,
  :cert => OpenSSL::X509::Certificate.new(File.read(cert)),
  :key => OpenSSL::PKey::RSA.new(File.read(key)),
  :ca_file => cacert
) do |http|
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request request
    jsongroup = JSON.parse(response.body).select {|g| g["name"] == group}[0]                                                                         
    jsongroup["classes"] = jsongroup["classes"].merge({ klass => {}})
    group_id = jsongroup["id"]
end

uri = URI('https://puppet:4433/classifier-api/v1/groups/' + group_id)

Net::HTTP.start(
  uri.host,
  uri.port,
  :use_ssl => uri.scheme == 'https',
  :verify_mode => OpenSSL::SSL::VERIFY_NONE,
  :cert => OpenSSL::X509::Certificate.new(File.read(cert)),
  :key => OpenSSL::PKey::RSA.new(File.read(key)),
  :ca_file => cacert
) do |http|
    request = Net::HTTP::Put.new(uri.request_uri,'Content-Type' => 'application/json')
    request.body = jsongroup.to_json
    response = http.request request
    puts response.body
end
