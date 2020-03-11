# Echo_Server --
#	Open the server listening socket
#	and enter the Tcl event loop
#
# Arguments:
#	port	The server's port number

proc Echo_Server {port} {
    set s [socket -server EchoAccept $port]
    #vwait forever
    return $s
}

# Echo_Accept --
#	Accept a connection from a new client.
#	This is called after a new socket connection
#	has been created by Tcl.
#
# Arguments:
#	sock	The new socket connection to the client
#	addr	The client's IP address
#	port	The client's port number
	
proc EchoAccept {sock addr port} {
    global echo

    # Record the client's information

    #puts "Accept $sock from $addr port $port"
    Modelo::aceptar $addr $port
    set echo(addr,$sock) [list $addr $port]

    # Ensure that each "puts" by the server
    # results in a network transmission

    fconfigure $sock -buffering line

    # Set up a callback for when the client sends data
    fileevent $sock readable [list Echo $sock]
}

# Echo --
#	This procedure is called when the server
#	can read data from the client
#
# Arguments:
#	sock	The socket connection to the client

proc Echo {sock} {
    global echo

    # Obtener dirección y puerto
    set params [lindex [array get echo "addr,$sock"] 1]
    set addr [lindex $params 0]
    set port [lindex $params 1]

    # Check end of file or abnormal connection drop,
    # then echo data back to the client.

    if {[eof $sock] || [catch {gets $sock line}]} {
	    close $sock
	    #puts "Close $echo(addr,$sock)"
        Modelo::cerrar $addr $port
	    unset echo(addr,$sock)
    } else {
        Modelo::responder $addr $port $line
	    puts $sock $line
    }
}
