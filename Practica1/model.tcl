# Agregar búsqueda de paquetes locales
lappend auto_path ../lib

package require Reactive
package require easygrid

source ../utils/Styles.tcl
source ../widgets/BarraEstado.tcl
source ../widgets/CajaMensajes.tcl
source ../widgets/LineEntry.tcl
source ../widgets/Scroller.tcl

namespace eval Modelo {
    # Puede ser inicial, conectado o desconectado
    variable estado inicial

    variable host localhost
    variable port 2540

    variable mensaje ""

    variable mensajes { }

    Reactive::inject Modelo

    Reactive::computed Modelo conectado { estado } {
        [string equal $estado "conectado"]
    }

    proc conectar { } {
        Modelo::assign estado "conectado"
    }

    proc desconectar { } {
        Modelo::assign estado "desconectado"
    }

    proc enviarMensaje { } {
        if {[llength $Modelo::mensaje] > 0} {
            set mensaje $Modelo::mensaje
            Modelo::assign mensaje ""

            if { $Modelo::conectado } {
                Modelo::modify mensajes {[concat $it "{right {$mensaje}}" "{left {$mensaje}}"]}
            }
        }
    }

    proc recibirMensaje { mensaje } {
        if { $Modelo::conectado } {
            Modelo::modify mensajes {[concat $it "{left {$mensaje}}"]}
        }
    }
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
ttk::entry .params.host -justify right -textvariable Modelo::host -width 15
ttk::entry .params.port -justify left  -textvariable Modelo::port -width 15
label .params.separador -text ":" -font $Styles::font -background white -fg $Styles::foreground

Entry::setup .params.host
Entry::setup .params.port

Modelo::whenSetup conectado {"disabled"} else {"enabled"} {
    .params.host configure -state $it
    .params.port configure -state $it
}

## Mensajes
set bgMensajes #FAFAFA
frame .areaMensajes -background $bgMensajes
label .areaMensajes.textoInicial -font "$Styles::fontName 14" \
    -bg $bgMensajes -justify center -fg $Styles::foreground \
    -text "Ingresa el nombre del host y\nel número de puerto para\n comenzar"

frame .areaMensajes.advertencia -background #EEEEEE
label .areaMensajes.advertencia.mensaje -font "$Styles::fontName 8" \
    -bg #EEEEEE -justify center -fg $Styles::foreground \
    -text "Tus mensajes no están cifrados\nde extremo a extremo"

Grid::rows    .areaMensajes.advertencia {1}
Grid::columns .areaMensajes.advertencia {1}
Grid::place   .areaMensajes.advertencia {
    {.mensaje 0 0 { 24 8 }}
}

## Cajas de mensajes
Scroller::new .areaMensajes.mensajes -background $bgMensajes

CajaMensajes::new .areaMensajes.mensajes.burbujas ::Modelo mensajes -background $bgMensajes \
                    -font "$Styles::fontName 10" \
                    -leftbg #D4D4D4 -leftfg #2D2D2D \
                    -rightbg #5755D9 -rightfg white

Scroller::setContent .areaMensajes.mensajes .burbujas
Modelo::listen mensajes {
    after 10 Scroller::update .areaMensajes.mensajes .burbujas
}

## Bloqueo
frame .areaMensajes.bloqueo         -background #E4E4E4
label .areaMensajes.bloqueo.mensaje -font $Styles::font \
    -bg #E4E4E4 -justify center -fg $Styles::foreground \
    -text "No puedes responder a esta conversación\nPorque no estás conectado"

Grid::rows    .areaMensajes.bloqueo {1}
Grid::columns .areaMensajes.bloqueo {1 0 1}
Grid::place   .areaMensajes.bloqueo {{.mensaje 0 1 { 24 8 }}}

## Entrada de texto
frame          .areaMensajes.entrada -background $bgMensajes
LineEntry::new .areaMensajes.entrada.mensaje ::Modelo mensaje    \
                                             -background $bgMensajes \
                                             -hinttext "Ingresa tu mensaje..." \
                                             -command Modelo::enviarMensaje
Modelo::listen conectado {
    if $it { 
        LineEntry::requestFocus .areaMensajes.entrada.mensaje 
    }
}

ttk::button    .areaMensajes.entrada.boton -text "Enviar" -command Modelo::enviarMensaje
Button::setup .areaMensajes.entrada.boton

Grid::rows    .areaMensajes.entrada {1}
Grid::columns .areaMensajes.entrada {1 0}
Grid::place   .areaMensajes.entrada horizontal {
    {.mensaje {8 8} "nsew" }
    {.boton   {8 8}}
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
    {barraEstado       "we"}
    {params            {0  8} "we"}
    {areaMensajes      {24 8} "nsew"}
    {manejadorConexion {0  8}}
}

Grid::rows    .params {1}
Grid::columns .params {1 0 0 0 1}

Grid::place .params {
    {.host      0 1}
    {.separador 0 2}
    {.port      0 3}
}

Modelo::listenSetup estado {
    Grid::clear .areaMensajes

    switch -glob $estado {
        inicial {
            Grid::rows    .areaMensajes {1}
            Grid::columns .areaMensajes {1}

            Grid::place .areaMensajes .textoInicial
        }

        "*conectado" {
            Grid::rows    .areaMensajes {0 1 0}
            Grid::columns .areaMensajes {1}

            Grid::place .areaMensajes vertical {
                {.advertencia {0 16}}
                {.mensajes "nsew" { 8 8 }}
            }
            
            switch $estado {
                conectado {
                    Grid::place .areaMensajes {
                        {.entrada  2 0 "ew"}
                    }
                }

                desconectado {
                    Grid::place .areaMensajes {{.bloqueo 2 0 "ew"}}
                }
            }
        }
    }
}
