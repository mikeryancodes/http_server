require 'socket'
require 'time'

class HTTPResponse
  class StatusUndefined < RuntimeError
  end

  class HeaderFieldClassError < RuntimeError
  end

  attr_accessor :status, :message_body, :headers

  VERBAL = {
    200 => "OK",
    400 => "Bad Request",
    404 => "Not Found",
    405 => "Method Not Allowed",
    501 => "Not Implemented"
  }

  def initialize(status = nil)
    @status = status
    @message_body = ""
    @headers = {
      "Date" => proc{ Time.now.httpdate },
      "Connection" => "close",
      "Server" => "Mike/1.0.0",
      "Content-Type" => "text/html",
      "Content-Length" => proc{ @message_body.length }
    }
  end

  def to_s
    raise StatusUndefined if @status.nil?
    result = "HTTP/1.1 #{@status} #{VERBAL[@status]}\r\n"
    @headers.each do |k, v|
      if v.class == String
        result << "#{k}: #{v}\r\n"
      elsif v.class == Proc
        result << "#{k}: #{v.call}\r\n"
      else
        raise HeaderFieldClassError
      end
    end
    if @message_body.length > 0
      result << "\r\n"
      result << @message_body
    end
    result
  end
end

class HTTPServer
  BAD_REQUEST = HTTPResponse.new(400)
  CONTENT_TYPE = Hash.new("application/octet-stream")
  CONTENT_TYPE["html"] = "text/html"
  CONTENT_TYPE["htm"] = "text/html"
  CONTENT_TYPE["shtml"] = "text/html"

  CONTENT_TYPE["rtf"] = "text/richtext"
  CONTENT_TYPE["txt"] = "text/plain"
  CONTENT_TYPE["css"] = "text/css"

  CONTENT_TYPE["jpeg"] = "image/jpeg"
  CONTENT_TYPE["gif"] = "image/gif"
  CONTENT_TYPE["png"] = "image/png"

  def initialize(port = 7777)
    @port = port
    @sock = TCPServer.new(@port)
    while @client = @sock.accept
      @match_data = @client.gets.match(/^([A-Z]+) ([^ ]+) HTTP\/1\.1/)
      @response = HTTPResponse.new
      @match_data.nil? ? @response = BAD_REQUEST : self.send(@match_data[1].downcase)
      response_as_string = @response.to_s
      puts response_as_string
      @client.print response_as_string
      @client.close
    end
  end

  def get
    get_file_contents(:get)
  end

  def head
    get_file_contents(:head)
  end

  def method_missing(method)
    if [:post, :put, :delete, :trace, :options, :connect, :patch].include?(method)
      @response.status = 405
    else
      @response.status = 501
    end
  end

  private

  def get_file_contents(method)
    begin
      file_name = @match_data[2]
      file = File.open(".#{file_name}", "rb") do |f|
        file_name_match_data = file_name.match(/(\/[^\/].+)*\/(([^\/\.]+)\.(.+))/)
        extension = file_name_match_data[4]
        @response.headers["Content-Type"] = CONTENT_TYPE[extension]
        @response.status = 200
        if method == :get
          @response.message_body = f.read
        else
          @response.headers["Content-Length"] = f.read.length.to_s
        end
      end
    rescue
      @response.status = 404
    end
  end
end

my_server = HTTPServer.new(7777)
