frame  .login
label  .login.host_label -text "Host"
entry  .login.host
label  .login.port_label -text "Puerto"
entry  .login.port
button .login.connect -text "Conectar"

grid columnconfigure .login 0 -weight 1
grid columnconfigure .login 1 -weight 3
grid columnconfigure .login 2 -weight 1

grid rowconfigure .login 0 -weight 1
grid rowconfigure .login 1 -weight 0
grid rowconfigure .login 2 -weight 0
grid rowconfigure .login 3 -weight 0
grid rowconfigure .login 4 -weight 0
grid rowconfigure .login 5 -weight 0
grid rowconfigure .login 6 -weight 1

grid .login.host_label -row 1 -column 1 -sticky w
grid .login.host       -row 2 -column 1 -sticky ew

grid .login.port_label -row 3 -column 1 -sticky w
grid .login.port       -row 4 -column 1 -sticky ew

grid .login.connect -row 5 -column 1 -sticky ew

grid .login -column 0 -row 0 -sticky nsew
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1
