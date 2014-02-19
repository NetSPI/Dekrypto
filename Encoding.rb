require 'uri'
require 'base64'
require 'cgi'
class Encoding
  attr_accessor :verbose
  def initialize()

  end

  def  self.bin_to_hex(s)
    s.unpack('H*').first
  end

  def self.hex_to_bin(s)
    s.scan(/../).map { |x| x.hex }.pack('c*')
  end


  def self.decode(s)
    #Reason for URI.unescape is because it will not unescape special characters like '+' and break base64 decoding process
    s=Base64.decode64(URI.unescape(s))
    s= Encoding.bin_to_hex(s)
    return s
  end
  


  def self.encode(s)
    s=Base64.strict_encode64(Encoding.hex_to_bin(s))
    ((s.length/76).floor).step(1,-1) do |i|
      begin
        s.insert(i*76,"\n")
      rescue IndexError
      end
    end
    #Reason for CGI.escape here so it wouldn't escape special characters like '+'
    return CGI.escape(s)

  end
end