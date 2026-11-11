# Manifiesto principal: indica qué configuración recibe cada servidor.
# Cualquier nodo (en este laboratorio, web01) recibe la clase webserver.

node default {
  class { 'webserver':
    titulo => 'Laboratorio Puppet - Equipo',
    color  => '#1f4e79',   
  }
}
