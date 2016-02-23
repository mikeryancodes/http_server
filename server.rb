require 'socket'
require 'time'

sock = TCPServer.new(7777)
while client = sock.accept
 request_line = client.gets
 puts request_line
 match_data = request_line.match(/^([A-Z]+) ([^ ]+) HTTP\/1\.1/)
 response = ""
 if match_data
   method = match_data[1].upcase
   file_name = match_data[2]
   case method
   when "GET"
     begin
       file = File.open(".#{file_name}", "r") do |f|
         response << "HTTP/1.1 200 OK\n\r"
         response << "Date: #{Time.now.rfc2822}\n\r"
         response << "Connection: close\n\r"
         response << "Server: Mike/1.0.0\n\r"
         response << "Accept-Ranges: bytes\n\r"
         response << "Content-Type: text/html\n\r"
         response << "Content-Length: length\n\r"
         response << "\n\r"
         response << f.read
       end
     rescue
       response << "HTTP/1.1 404 Not Found\n\r"
       response << "Date: #{Time.now.rfc2822}\n\r"
       response << "Connection: close\n\r"
       response << "Server: Mike/1.0.0\n\r"
       response << "Accept-Ranges: bytes\n\r"
       response << "Content-Type: text/html\n\r"
       response << "Content-Length: length\n\r"
       response << "\n\r"
     end
   when "HEAD" || "POST" || "PUT" || "DELETE" || "TRACE" || "OPTIONS" || "CONNECT" || "PATCH"
     response << "HTTP/1.1 405 Method Not Allowed\n\r"
     response << "Date: #{Time.now.rfc2822}\n\r"
     response << "Connection: close\n\r"
     response << "Server: Mike/1.0.0\n\r"
     response << "Accept-Ranges: bytes\n\r"
     response << "Allow: GET"
     response << "Content-Type: text/html\n\r"
     response << "Content-Length: length\n\r"
     response << "\n\r"
   else
     response << "HTTP/1.1 501 Not Implemented\n\r"# unrecognized method
     response << "Date: #{Time.now.rfc2822}\n\r"
     response << "Connection: close\n\r"
     response << "Server: Mike/1.0.0\n\r"
     response << "Accept-Ranges: bytes\n\r"
     response << "Allow: GET"
     response << "Content-Type: text/html\n\r"
     response << "Content-Length: length\n\r"
     response << "\n\r"
   end
 else
   response << "Unrecognized request"
 end
 loop do
   header_field = client.gets
   case header_field
   when "Accept-Charset"
   when "Accept-Encoding"
   when "Accept-Language"
   when "Authorization"
   when "Expect"
   when "From"
   when "Host"
   when "If-Match"
   when "If-Modified-Since"
   when "If-None-Match"
   when "If-Range"
   when "If-Unmodified-Since"
   when "Max-Forwards"
   when "Proxy-Authorization"
   when "Range"
   when "Referer"
   when "TE"
   when "User-Agent"
   else
     break
   end
 end
 message_body = client.gets
 client.puts response
 client.close
 puts response
end
