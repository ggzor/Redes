package provide functional 0.1

namespace eval Functional {
    proc partial {target method args} {
        set srcParams [lrange [info args $method] [llength $args] end]

        # Retrieve parameters and defaults
        set params {}
        foreach arg $srcParams {
            if [info default $method $arg argdef] {
                lappend params "$arg $argdef"
            } else {
                lappend params $arg
            }
        }

        # Attach dollar sign to params
        set forwardParams {}
        foreach param $srcParams {
            set forwardParams [concat $forwardParams "\$$param"]
        }

        # Generate body
        set body [concat $method $args $forwardParams]

        proc $target $params $body
    }
}
