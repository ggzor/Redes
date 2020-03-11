package require argsparse
package require closure
package require easygrid
package require Reactive 

namespace eval CajaMensajes {
    variable subWidgetCount 0

    variable options "
                elementPath
                model
                variable
                -background white
                -foreground black
                -font {$Styles::font}
                -rightbg white -rightfg black
                -leftbg black -leftfg white"

    proc get_id { } {
        set id $::CajaMensajes::subWidgetCount
        incr ::CajaMensajes::subWidgetCount
    }

    proc new args {
        Args::parse $args $CajaMensajes::options

        frame $elementPath -background $background
        grid propagate $elementPath no

        # Reconfigure columns
        Grid::columns $elementPath {1 0 1}
        grid columnconfigure $elementPath 0 -uniform a -minsize 60
        grid columnconfigure $elementPath 1 -minsize 50
        grid columnconfigure $elementPath 2 -uniform a -minsize 60

        Reactive::listen $model $variable [Closure::of [Args::vars $CajaMensajes::options] {
            set count [llength $old] 

            foreach msg [lrange $it $count end] {
                set id [CajaMensajes::get_id]
                set position [lindex $msg 0]
                set msg      [lindex $msg 1]

                set container "$elementPath.$id"

                set bg [set "${position}bg"]
                set fg [set "${position}fg"]

                frame $container -bg $bg

                # Watch resizing
                bind . <Configure> "+ 
                    set bounds \[grid bbox $elementPath 0 0]
                    set w \[lindex \$bounds 2]
                    $container.text configure -wraplength \[expr {\$w - 32}]
                "

                label "$container.text" -text $msg \
                    -background $bg -foreground $fg -font $font \
                    -justify left

                Grid::rows    $container {1}
                Grid::columns $container {1}
                Grid::place   $container {{.text {16 8}}}

                switch $position {
                    left {
                        grid $container -row $count -column 0 -sticky nsw -pady 2
                    }
                    right {
                        grid $container -row $count -column 2 -sticky nse -pady 2
                    }
                }

                incr count
            }
        }]
    }
}