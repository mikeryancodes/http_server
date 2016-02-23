require 'socket'
require 'time'

# TODO: Needs to be able to handle more complex file operations
# Need to have a closer look at headers

class HTTPResponse
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
    result = "HTTP/1.1 #{@status} #{VERBAL[@status]}\n\r"
    @headers.each do |k, v|
      if v.class == String
        result << "#{k}: #{v}\n\r"
      elsif v.class == Proc
        result << "#{k}: #{v.call}\n\r"
      else
        raise HeaderFieldClassError
      end
    end
    if @message_body.length > 0
      result << "\n\r"
      result << @message_body
    end
    result
  end
end

class HTTPServer
  BAD_REQUEST = HTTPResponse.new(400)

  def initialize(port = 7777)
    @port = port
    @sock = TCPServer.new(@port)
    while @client = @sock.accept
      @match_data = @client.gets.match(/^([A-Z]+) ([^ ]+) HTTP\/1\.1/)
      @response = HTTPResponse.new
      @match_data.nil? ? @response = BAD_REQUEST : self.send(@match_data[1].downcase)
      response_as_string = @response.to_s
      puts response_as_string
      @client.puts response_as_string
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
      file = File.open(".#{@match_data[2]}", "r") do |f|
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
