# Agregar búsqueda de paquetes locales
lappend auto_path ../lib

package require Reactive
package require easygrid

source ../utils/Styles.tcl
source ../widgets/BarraEstado.tcl
source ../widgets/CajaMensajes.tcl
source ../widgets/LineEntry.tcl
source ../widgets/Scroller.tcl

source echo_server.tcl

namespace eval Modelo {
    # Puede ser inicial, conectado o desconectado
    variable estado inicial

    variable port 2540
    variable conexion none

    variable log "Establece el número de puerto para comenzar"

    Reactive::inject Modelo

    Reactive::computed Modelo conectado { estado } {
        [string equal $estado "conectado"]
    }

    proc log { mensaje } {
        if {[llength $Modelo::log] == 0} {
            Modelo::assign log $mensaje
        } else {
            Modelo::modify log {"$it\n$mensaje"}
        }
    }

    proc conectar { } {
        Modelo::assign estado "conectado"
        set Modelo::conexion [Echo_Server $Modelo::port]

        Modelo::log "Conectado en el puerto $Modelo::port"

        vwait forever
    }

    proc desconectar { } {
        if $Modelo::conectado {
            global echo

            Modelo::assign estado "desconectado"
            close $Modelo::conexion
            
            foreach name [array names echo] {
                set params [lindex [array get echo $name] 1]
                set addr [lindex $params 0]
                set port [lindex $params 1]
                set name [string range $name 5 end]
                
                catch {close $name}
                Modelo::log "Conexión cerrada $addr:$port"
            }

            Modelo::log "Desconectado del puerto $Modelo::port"
        }
    }

    proc aceptar { addr port } {
        Modelo::log "Cliente aceptado en $addr:$port"
    }

    proc cerrar { addr port } {
        Modelo::log "Cliente desconectado $addr:$port"
    }

    proc responder { addr port mensaje } {
        if {[llength $mensaje] > 0} {
            Modelo::log "Respondiendo $addr:$port <- $mensaje"
        }
    }
}

# Manejar cierre de la ventana
wm protocol . WM_DELETE_WINDOW {
    Modelo::desconectar

    exit
}

# Interfaz
## Ventana
Styles::initialize
. configure -background white -padx 0 -pady 0 -relief flat -borderwidth 0

## Configurar ancho y alto de la ventana
set ancho 400
set alto  600
set x [expr {([winfo vrootwidth  .] - $ancho) / 2}]
set y [expr {([winfo vrootheight .] - $alto)  / 2}]
wm geometry . "${ancho}x${alto}+$x+$y"

## Barra de estado
BarraEstado::new .barraEstado
Modelo::listen conectado {BarraEstado::establecerConectado .barraEstado $it}

## Entradas de texto
frame .params -background white
label .params.labelpuerto -text "Puerto: " -font $Styles::font \
    -background white -fg $Styles::foreground
ttk::entry .params.port -justify center  -textvariable Modelo::port -width 8

Entry::setup .params.port

Modelo::whenSetup conectado {"disabled"} else {"enabled"} {
    .params.port configure -state $it
}

## Mensajes
text .areaMensajes -borderwidth 0 \
    -background #FAFAFA
# No permitir entrada de texto
bind .areaMensajes <KeyPress> break

Modelo::listenSetup log {
    .areaMensajes configure -state normal
    .areaMensajes replace 1.0 end $it
    .areaMensajes configure -state disabled
}

# Manejo de conexion
ttk::button .manejadorConexion
Button::setup .manejadorConexion

.manejadorConexion configure -command { if $Modelo::conectado Modelo::desconectar "else" Modelo::conectar }

Modelo::whenSetup conectado {{Secondary Desconectar}} else {{Primary Conectar}} {
    Button::setup .manejadorConexion   [lindex $it 0]
    .manejadorConexion configure -text [lindex $it 1]
}

# Layout
Grid::rows    . {0 0 1 0}
Grid::columns . {1}

Grid::place . vertical {
    {barraEstado             "we"}
    {params            {0 8} "we"}
    {areaMensajes      {24 8} "nsew"}
    {manejadorConexion {0 8}}
}

Grid::rows .params {1}
Grid::columns .params {1 0 0 1}

Grid::place .params {
    {.labelpuerto 0 1 {8 0}}
    {.port 0 2}
}
