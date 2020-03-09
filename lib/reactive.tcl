package provide Reactive 0.1

package require closure

namespace eval ::Reactive {
    # Prepares a namespace object to use reactive properties
    proc inject { object } {
        # Attach reactive shorthand utility methods that forward to reactive methods
        proc "::${object}::modify" { path transform } \
            "Reactive::modify $object \$path \$transform"

        proc "::${object}::listen" { path {transform id} {callback none} } \
            "Reactive::listen $object \$path \$transform \$callback"
    
        proc "::${object}::listenSetup" { path {transform id} {callback none} } \
            "Reactive::listenSetup $object \$path \$transform \$callback"

        proc "::${object}::when" { path trueTransform else falseTransform body } \
            "Reactive::when $object \$path \$trueTransform else \$falseTransform \$body"
        
        proc "::${object}::whenSetup" { path trueTransform else falseTransform body } \
            "Reactive::whenSetup $object \$path \$trueTransform else \$falseTransform \$body"

        # Declare required variables in target namespace object
        
        # Callback register
        variable "::${object}::callbacks"
        # Computed properties register
        variable "::${object}::computed"
        # Callback number generator state
        variable "::${object}::callbacksCount" 0
    }

    # Sets the value to the result of evaluating transform with the current
    # value as context (it)
    proc modify { object path transform } {
        set it [set [Reactive::evalPath $object $path]]
        set newValue [expr $transform]

        # If it has the same value, doesn't have to change
        if [string equal $it $newValue] return

        Reactive::setPath $object $path $newValue
        Reactive::notify $object $path $it $newValue
    }

    # Register a callback for a given object path with the corresponding transform
    # The transform is applied to the oldValue and newValue
    proc listen { object paths { transform id } { callback none } } {
        # Get and update callback index
        set id [eval "set ${object}::callbacksCount"]
        set "${object}::callbacksCount" [expr {$id + 1}]
        
        # Set the callback and transformation if necessary
        if {$callback eq "none"} {
            foreach singlePath $paths {
                dict set "${object}::callbacks" $singlePath $id "notransform \{$transform\} \{$paths\}"
            }
        } else {
            foreach singlePath $paths {
                dict set "${object}::callbacks" $singlePath $id "transform \{$transform\} \{$callback\} \{$paths\}"
            }
        }

        # Return the id
        expr $id
    }

    # Same as Reactive::listen, but invokes the callback once after the register is done
    # if $paths is a single path, $old and $it are the current value of the path, otherwise both are none
    proc listenSetup { object paths { transform id } { callback none } } {
        Reactive::listen $object $paths $transform $callback

        # Reorder parameters
        if [string equal $callback none] {
            set callback $transform
            set transform id
        }

        # Get current path value
        set currValue none
        if [llength $paths] {
            set currValue [Reactive::getPath $object $paths]
        }

        # Invoke callback once
        Reactive::invokeCallback $object $paths $currValue $currValue $callback $transform
    }

    # Sets a callback in path which notifies "expr $trueTransform" if the
    # watched value changes to true, and to "expr $falseTransform" otherwise
    proc when { object path trueTransform else falseTransform body } {
        if {$else ne "else"} {
            error "else parameter has to be else"
        }

        Reactive::listen $object $path [Closure::of {trueTransform falseTransform body} {
            if $it {
                set it [expr "$trueTransform"]
                eval $body
            } else {
                set it [expr "$falseTransform"]
                eval $body
            }
        }]
    }

    # The analogous to Reactive::listenSetup but for Reactive::when
    proc whenSetup { object path trueTransform else falseTransform body } {
        Reactive::when $object $path $trueTransform $else $falseTransform $body

        set value [Reactive::getPath $object $path]

        if $value {
            set value [expr "$trueTransform"]
        } else {
            set value [expr "$falseTransform"]
        }

        Reactive::invokeCallback $object $path none $value $body id
    }

    # Creates a computed property with name $path which responds
    # to each given dependency, evaluating body as its result
    proc computed { object path deps body } {
        # Bind all deps to its current value
        foreach var $deps { set $var [Reactive::getPath $object $var] }
        # Calculate initial value
        Reactive::setPath $object $path [expr $body]
        # Unbind all deps
        foreach var $deps { unset $var }

        Reactive::listen $object $deps [Closure::of {object path body} {
            set oldValue [Reactive::getPath $object $path]
            Reactive::setPath $object $path [expr "$body"]
            set newValue [Reactive::getPath $object $path]
            Reactive::notify $object $path $oldValue $newValue
        }]
    }

    # Utilities to manage path names
    proc evalPath { object path } {
        return "::${object}::$path"
    }

    proc getPath { object path } {
        set [Reactive::evalPath $object $path]
    }

    proc setPath { object path value } {
        set [Reactive::evalPath $object $path] $value
    }

    # Notifies all the listeners of the path in object
    proc notify { object path oldValue newValue } {
        set callbacks "${object}::callbacks"

        # If it has the same value, doesn't have to change
        if [string equal $oldValue $newValue] return

        # Chack if there are associated callbacks
        if [info exists $callbacks] {
            if [dict exists [set $callbacks] $path] {
                dict for {_ cb} [dict get [set $callbacks] $path] {
                    # If has transform argument
                    if {[lindex $cb 0] eq "transform" } {
                        set transform [lindex $cb 1]
                        set deps [lindex $cb 3]
                        set cb [lindex $cb 2]
                    } else {
                        set transform id
                        set deps [lindex $cb 2]
                        set cb [lindex $cb 1]
                    }
                    
                    Reactive::invokeCallback $object $deps $oldValue $newValue $cb $transform
                }
            }
        }
    }

    # Invokes the given callback with the given dependencies as local variables
    # And the shorthand it and old variables
    proc invokeCallback { object deps oldValue newValue cb {transform id} } {
        # Apply supplied transform if required
        if [expr "![string equal $transform "id"]"] {
            set it $oldValue
            set oldValue [expr $transform]

            set it $newValue
            set newValue [expr $transform]
        }

        # Setup context with dependencies
        foreach var $deps { set $var [Reactive::getPath $object $var] }

        # Invoke with shorthand vars
        set old $oldValue
        set it $newValue

        Closure::run [concat $deps old it] $cb
    }
}
