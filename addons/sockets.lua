--- @meta

--- @class Socket
sock = {}

--- Create a socket.
--- `addr` is a string consisting of the protocol (`tcp://` or `udp://`), the ip address, followed by a port number ":1234". ipv6 addresses should be enclosed in square brackets.
--- 
--- To create a socket that listens to any incoming traffic on a given port, use * for the address.
--- 
--- A socket with remote hosts writing (or connecting to) that port can then be accepted using sock:accept(). Listener sockets can not be created while a process is sandboxed. i.e. BBS carts can proactively connect to a particular address, but can not receive connections from arbitrary sources.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#socket)
--- @param addr string The address of the socket, starting with `tcp://` or `udp://`, followed by ipv4 address, ipv6 address, a domain name, or a wildcard `*`, ending with a port separated by a colon.
--- @return Socket socket A newly opened socket.
function socket(addr) end

--- Read a string from a socket. This function is not blocking; it will return nothing when there is no data available on the socket.
--- 
--- Returns the number of bytes written, or nil followed by an error message string.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_read)
--- @class Socket
--- @return string msg
function sock:read() end

--- Write string str to socket.

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_write)
--- @class Socket
--- @param str string The string to write to the socket.
--- @return number bytes_written The number of bytes written to the socket.
function sock:write(str) end

--- Close the connection if there is one.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_close)
--- @class Socket
function sock:close() end

--- Returns a string describing the sockets status
---
--- "ready" means the socket that is ready to read/write to a given address
---
--- "listening" means the socket was created with a wildcard address and ready to :accept() connections
---
--- "closed" means :close() was called on the socket
---
--- "closed by peer" means that the peer closed the connection (happens after attempt to :read)
---
--- "disconnected" means the socket was closed for some other reason
---
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_status)
--- @class Socket
--- @return "ready" | "listening" | "closed" | "closed by peer" | "disconnected" | "invalid"
function sock:status() end

--- This can be used with sockets that are listening to all traffic on a given port. When a new connection is made with tcp, or a UDP message is receieved from a new address+port, :accept() will return a new socket that can be used to communicate with that particular client, or nil if none found.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_accept)
--- @class Socket
--- @return Socket client_socket
function sock:accept() end
