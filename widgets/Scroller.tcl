package require argsparse
package require closure
package require easygrid
package require Reactive

namespace eval ::Scroller {
    Reactive::inject LineEntry

    variable inFocus none

    variable options "
                elementPath
                -background white"

    proc new args {
        Args::parse $args $Scroller::options

        frame $elementPath -background $background
        Grid::rows $elementPath {1}
        Grid::columns $elementPath {1}

        canvas $elementPath.canvas -relief flat -background $background -borderwidth 4

        Grid::place $elementPath {{.canvas 0 0 nsew}}
    }

    proc update { elementPath content } {
        set wcanvas [winfo width $elementPath.canvas]
        set hcanvas [winfo height $elementPath.canvas]

        set hcontent 0

        foreach child [grid slaves $elementPath$content] {
            incr hcontent [expr {8 + [winfo height $child]}]
        }

        set finalHeight [expr {max($hcanvas, $hcontent)}]

        $elementPath.canvas itemconfigure content -width $wcanvas -height $finalHeight
        $elementPath.canvas configure -scrollregion "1 1 $wcanvas $finalHeight"

        if {$finalHeight > $hcanvas} {
            set percentage [expr {1 - (double($hcanvas) / double($finalHeight))}]
            $elementPath.canvas yview moveto $percentage
        }
    }

    proc setContent { elementPath content } {
        set background [$elementPath cget -background]
        $elementPath.canvas create window 0 0 -anchor nw -tags content -window "$elementPath$content"

        frame $elementPath.coverTop -background $background -height 8
        frame $elementPath.coverLeft -background $background -width 8

        Grid::place $elementPath {{.coverTop 0 0 "new"} {.coverLeft 0 0 "nsw"}}

        bind $elementPath <Configure> "::Scroller::update $elementPath $content"
    }
}
