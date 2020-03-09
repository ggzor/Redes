package provide closure 0.1

namespace eval ::Closure {
    # Captures the values of the given vars in a var-value dict
    proc capture vars {
        set values [dict create]

        foreach var $vars {
            dict set values $var [uplevel set $var]
        }

        set values
    }

    # Sets the given variables in the var-value dict in the current context
    proc inject vars {
        dict for {var value} $vars {
            uplevel set $var $value
        }
    }

    # Create a new closure of the given vars
    proc of {vars body} {
        set values [uplevel Closure::capture "\"$vars\""]

        return "closure {$values} $body"
    }

    # Run a closure if it is a closure, otherwise eval as a normal proc
    proc run {vars {closure none}} {
        if {$closure eq "none"} {
            set closure $vars
            set vars {}
        }

        set injectedVars [uplevel Closure::capture "\"$vars\""]

        if {[lindex $closure 0] eq "closure"} {
            set values [lindex $closure 1]
            set body   [lrange $closure 2 end]

            Closure::inject $injectedVars
            Closure::inject $values

            eval $body
        } else {
            eval $closure
        }
    }
}
