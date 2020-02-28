package provide argsparse 0.1

namespace eval ::Args {
    # Given an args configuration and a parameter list sets the variables
    # to their parameter values or defaults in the current scope.
    proc parse { parameters config } {
        set positional {}
        set positionalValues {}

        # Iterate over both lists and fill options and arguments
        set i 0
        foreach var [list $config $parameters] {
            while {[llength $var] > 0} {
                # Search for options
                if [regexp {^\-(\w+)\s+(\w+)} $var _ option value] {
                    uplevel set $option $value
                    set var [lrange $var 2 end]
                } else {
                    # Search for positional arguments
                    switch $i {
                        0 { lappend positional [lindex $var 0] }
                        1 { lappend positionalValues [lindex $var 0] }
                    }
                    
                    set var [lrange $var 1 end]
                }
            }

            incr i
        }

        if {[llength $positional] != [llength $positionalValues]} {
            error "Not enough positional args were given"
        }

        foreach option $positional value $positionalValues {
            uplevel set $option $value
        }
    }
}
