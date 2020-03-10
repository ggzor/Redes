package provide argsparse 0.1

namespace eval ::Args {
    # Returns the name of the arguments in the configuration
    proc vars config {
        Args::args $config vars _ _
        return $vars
    }

    # Returns all the args in config, separated
    #   positionalVar will contain the postional variables in order
    #   optionsVar will contain the options with its defaults
    proc args {config allVar positionalVar optionsVar} {
        uplevel "set $allVar {}"
        uplevel "set $positionalVar {}"
        uplevel "set $optionsVar {}"
        
        while {[llength $config] > 0} {
            set first  [lindex $config 0]
            set value  [lindex $config 1]

            if [regexp {^\-(\S+)} $first _ option] {
                # Search for options
                uplevel lappend $allVar      $option
                uplevel lappend $optionsVar "$option $value"

                set config [lrange $config 2 end]
            } else {
                # Search for positional arguments
                uplevel lappend $allVar        $first
                uplevel lappend $positionalVar $first
                
                set config [lrange $config 1 end]
            }
        }
    }

    # Given an args configuration and a parameter list sets the variables
    # to their parameter values or defaults in the current scope.
    proc parse { parameters config } {
        set positional {}
        set positionalValues {}

        # Iterate over both lists and fill options and arguments
        set i 0
        foreach var [list $config $parameters] {
            while {[llength $var] > 0} {
                set first  [lindex $var 0]
                set value  [lindex $var 1]

                # Search for options
                if [regexp {^\-(\S+)} $first _ option] {
                    uplevel set $option "\{$value\}"
                    set var [lrange $var 2 end]
                } else {
                    # Search for positional arguments
                    switch $i {
                        0 { lappend positional       $first }
                        1 { lappend positionalValues $first }
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
