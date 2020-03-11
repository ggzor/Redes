# General styles configuration
namespace eval Styles {
    variable initializers
    variable kinds

    # Configuration
    variable fontName "Helvetica"
    variable font "$Styles::fontName 10"
    variable foreground black

    # Register a new kind of element
    proc registerKind { kind } { lappend Styles::kinds $kind }

    # Run all the initializers
    proc initialize { } {
        # If name starts with @, args are forwarded, otherwise it is executed
        # and the name is stored in the variable name
        proc callIfExists { name args } {
            set takesArgs no

            if { [string match "@*" $name] } {
                set takesArgs yes
                set name [string range $name 1 end]
            }

            if [llength [namespace which $name]] {
                if $takesArgs { 
                    $name {*}$args
                } else {
                    eval [lindex $args 0]
                }
            }
        }

        foreach kind $Styles::kinds {
            # Generic initialization, using configuration
            dict for {class propsByClass} [Styles::config $kind] {
                dict for {prop propValues} $propsByClass {
                    # Example: ttk::style map Normal.TButton -background [lrange [Styles::config Button Normal background] 2 end]
                    eval "ttk::style map ${class}.T$kind -$prop \[lrange \[Styles::config $kind $class $prop\] 2 end\]"

                    # Example: ttk::style configure Normal.TButton -background [Styles::config Button Normal background normal]
                    eval "ttk::style configure $class.T$kind -$prop \[Styles::config $kind $class $prop normal\]"
                }
            }

            callIfExists "@${kind}::initialize"
            callIfExists "${kind}::initializeClass" "
                dict for {class _} \[Styles::config $kind\] { 
                    \$name \$class
                }"
        }
    }

    # Helper procs to setup styles
    proc config { kind args } {dict get [set "${kind}::configuration"] {*}$args}

    proc setConfig { kind class args } {
        set command "dict set ${kind}::configuration \$class $args"

        if { $class eq "all" } {
            dict for {class _} [Styles::config $kind] { 
                eval $command 
            }
        } else {
            eval $command
        }
    }
}

# Entry styles configuration
namespace eval Entry {
    variable configuration {
        Normal {
            background {
                normal   #E7E7E7
                disabled #FAFAFA
                focus    #BFBFBF
                hover    #D2D2D2 
            }

            foreground {
                normal   black
                disabled #636363
            }

            padding { normal { 6 4 } }

            relief { normal flat }
        }
        NoDecorations {
            background {
                normal   #FAFAFA
                disabled #FAFAFA
                focus    #FAFAFA
                hover    #FAFAFA
            }
            foreground {
                normal black
                disabled #636363
            }
            padding { normal { 6 4 } }
            relief { normal flat }
        }
    }

    Styles::setConfig Entry all font normal $Styles::font

    proc initializeClass { class } {
        # Fix layout to remove border
        ttk::style layout "${class}.TEntry" { 
            Entry.highlight -sticky nsew -children { 
                Entry.border -border 1 -children { 
                    Entry.padding -sticky nsew -children { 
                        Entry.textarea -sticky nsew 
                    } 
                }
            }
        }
    }    
    
    proc setup { elem { autoselect yes } { type Normal } } {
        # Set default configuration
        $elem configure -font $Styles::font -style "${type}.TEntry"

        if { $autoselect } {
            # Set selection when focus
            bind $elem <FocusIn> "after 100 \"$elem selection range 0 end; $elem icursor end\""
            bind $elem <FocusOut> "$elem selection clear"
        }
    }
}
Styles::registerKind Entry

namespace eval Button {
    variable configuration {
        Primary {
            background {
                normal   #5755D9
                pressed  #3735AE
                active   #4240d4
                disabled #9A99E8
            }

            foreground {
                normal #fff
                disabled #DDDDF7
            }

            relief {
                normal  flat
                pressed flat
            }

            shiftrelief {
                normal 0
            }
        }

        Secondary {
            background {
                normal #F2F2F2
                pressed #BFBFBF
                active #E7E7E7
            }

            relief {
                normal flat
                pressed flat
            }

            shiftrelief {
                normal 0
            }
        }
    }
    Styles::setConfig Button Primary focuscolor [Styles::config Button Primary background]
    Styles::setConfig Button Secondary focuscolor [Styles::config Button Secondary background]

    proc initializeClass { class } {
        ttk::style configure "$class.TButton" -font $Styles::font
    }

    proc setup { elem {type Primary} } { 
        $elem configure -style "${type}.TButton"
    }
}
Styles::registerKind Button
