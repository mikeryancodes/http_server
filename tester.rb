require 'socket'
server = TCPSocket.new('localhost', 7777)
server.puts "HEAD /index.html HTTP/1.1\n\r"
server.puts "\n\r"
puts "Server says: #{server.gets}"
server.close

