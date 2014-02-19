##
# KryptoTestServer - adapted from Ron's RemoteTestServer.rb
# Created: December 10, 2012
# By: Ron Bowes
#
# A very simple application that is vulnerable to a padding oracle
# attack. A Sinatra app with two paths - /encrypt and /decrypt. /encrypt
# sends data encrypted with the current key, and /decrypt attempts to
# decrypt it but only reveals whether or not it was successful.
##

require 'base64'
require 'openssl'
require 'sinatra'
require './Encoding'

set :port, 20222

# Note: Don't actually generate keys like this!
@@key = (1..32).map{rand(255).chr}.join
@@iv
get '/encrypt' do
  text = "storeId=1996&userName=derp%20&password=this+is+a+secure+password&promotionCode=SPRING+2013"
  c = OpenSSL::Cipher::Cipher.new("des3")
  #@@iv = c.random_iv
  c.encrypt
  c.key = @@key
  data =(c.update(text) + c.final).unpack("H*")
  return "http://localhost:20222/krypto=" +Encoding.encode(data.join)
end

get /\/krypto=(.+)$/ do |data|
  begin
    data, newline= Encoding.decode(data)
    data = [data].pack("H*")
    c = OpenSSL::Cipher::Cipher.new("des3")
    c.decrypt
    #c.iv=@@iv
    c.key = @@key
    decrypt=   c.update(data) + c.final
    return "Success"
  rescue
    return "Fail"
  end
end