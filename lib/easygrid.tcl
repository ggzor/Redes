package provide easygrid 0.1

namespace eval ::Grid {
    # Sets up the rows with the specified weights
    proc rows {elem rows} {
        for {set i 0} {$i < [llength $rows]} {incr i} {
            grid rowconfigure $elem $i -weight [lindex $rows $i]
        }
    }

    # Sets up the columns with the specified heights
    proc columns {elem columns} {
        for {set i 0} {$i < [llength $columns]} {incr i} {
            grid columnconfigure $elem $i -weight [lindex $columns $i]
        }
    }

    # Places the elements described in values inside the parent with the given configuration
    # Syntax: config ::= (horizontal | vertical) [default row (v) or default column (h), default is 0 ]
    #         values ::= { value value ... }
    #         value  ::= { path (without parent path) [row] [column] ["nsew"] [{ padx pady }] }
    # Example: Grid::place .parent {vertical 1} {{.child 2} {.secondchild 3 4 "ne" {24 16}}}
    proc place {parent config {values none}} {
        set variadic none

        set defaultColumn 0
        set defaultRow 0

        # Set defaults
        if {$values eq "none"} {
            set values $config
        } elseif {[lindex $config 0] eq "vertical"} {
            set variadic row

            if {[llength $config] == 2} {
                set defaultColumn [lindex $config 1]
            }
        } elseif {[lindex $config 0] eq "horizontal"} {
            set variadic column

            if {[llength $config] == 2} {
                set defaultRow [lindex $config 1]
            }
        }

        set idx 0
        # Process each value
        foreach val $values {            
            # Set the non variadic var to its default
            switch $variadic {
                row { set column $defaultColumn }
                column { set row $defaultRow }
                none {
                    set column $defaultColumn
                    set row $defaultRow
                }
            }

            set $variadic $idx
            set elem [lindex $val 0]
            set stickyness ""
            set padx 0
            set pady 0


            # Separate integers
            set ints { }

            foreach param [lrange $val 1 end] {
                if [regexp {^\d+$} $param] {
                    lappend ints $param
                } elseif [regexp {^[nsew]+$} $param] {
                    set stickyness $param
                } else {
                    set padx [lindex $param 0]
                    set pady [lindex $param 1]
                }
            }

            # Parse int parameters
            set i 0
            foreach int $ints {
                switch $variadic {
                    none { switch $i {
                        0 { set row $int }
                        1 { set column $int }
                    }}

                    row { switch $i {
                        0 { set column $int }
                    }}

                    column { switch $i {
                        0 { set row $int }
                    }}
                }

                incr i
            }

            # Attach to parent
            grid "${parent}${elem}" -row $row -column $column \
                -sticky $stickyness -padx $padx -pady $pady

            incr idx
        }
    }

    # Clears grid configuration and removes elements
    proc clear { parent } {
        grid rowconfigure    $parent all -weight 0
        grid columnconfigure $parent all -weight 0

        foreach elem [grid slaves $parent] {
            grid remove $elem
        }
    }
}
