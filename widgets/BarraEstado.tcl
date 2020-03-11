namespace eval BarraEstado {
    namespace eval Color {
        variable Desconectado #CC4F40
        variable Conectado #16BC27
    }

    proc new { name } {
        label $name -background $BarraEstado::Color::Desconectado \
                    -foreground white -font "$Styles::font bold"  \
                    -text "Desconectado" -padx 0 -pady 4
    }

    proc establecerConectado { name conectado } {
        if $conectado { 
            $name configure -background $BarraEstado::Color::Conectado -text "Conectado" 
        } else {
            $name configure -background $BarraEstado::Color::Desconectado -text "Desconectado"
        }
    }
}
