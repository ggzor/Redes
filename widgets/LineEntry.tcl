package require argsparse
package require closure
package require easygrid
package require Reactive

source ../utils/Styles.tcl

namespace eval ::LineEntry {
    Reactive::inject LineEntry

    variable inFocus none

    variable options "
                elementPath
                model
                variable
                -background white
                -command none
                -font {$Styles::font}
                -hinttext {}"

    proc new args {
        Args::parse $args $LineEntry::options

        set textvariable "::${model}::${variable}"

        frame       $elementPath        -background $background
        ttk::entry "$elementPath.entry" -background $background -textvariable $textvariable -font $Styles::font
        label      "$elementPath.hint"  -background $background -text $hinttext -font $Styles::font \
                                        -foreground #969696 -cursor xterm
        frame      "$elementPath.line"  -height 2

        Entry::setup $elementPath.entry yes NoDecorations

        if { $command ne "none" } "
            bind $elementPath.entry <Return> $command
        "

        bind "$elementPath.entry" <FocusIn> "
            LineEntry::assign inFocus \"$elementPath\"
            grid remove $elementPath.hint
        "

        bind "$elementPath.entry" <FocusOut> "
            LineEntry::assign inFocus none

            if {\[llength \[set $textvariable]] == 0} {
                grid $elementPath.hint
            }
        "

        bind "$elementPath.hint" <Button-1> "
            grid remove $elementPath.hint
            focus $elementPath.entry
        "

        eval {"${model}::listen" $variable {[llength $it]} "
            if { \$it == 0 && (\[set LineEntry::inFocus] ne \"$elementPath\") } {
                grid $elementPath.hint
            } else {
                grid remove $elementPath.hint
            }
        "}

        LineEntry::listenSetup inFocus "\$it eq \"$elementPath\"" "
            if \$it {
                $elementPath.line configure -background #5755D9
            } else {
                $elementPath.line configure -background #787878
            }
        "

        Grid::rows    $elementPath {1 0}
        Grid::columns $elementPath {1}
        Grid::place $elementPath {
            {.entry 0 0 "nsew"}
            {.hint  0 0 "nsw"}
            {.line  1 0 "ew"}
        }
    }

    proc requestFocus elem {
        focus "$elem.entry"
    }
}
