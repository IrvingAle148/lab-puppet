# Clase webserver: deja un servidor web Apache en el estado deseado.
# Agrupa tres recursos (paquete, archivo y servicio) bajo un solo nombre.
class webserver (
  String $titulo = 'Laboratorio Puppet',
  String $color  = '#1f4e79',
) {

  # Facts: datos que Facter recopila del propio servidor.
  # Buscamos la IP de la red privada del laboratorio (192.168.56.x).
  $ips_privadas = $facts['networking']['interfaces'].filter |$nombre, $datos| {
    "${datos['ip']}" =~ /^192\.168\.56\./
  }.map |$nombre, $datos| { $datos['ip'] }

  $ip = empty($ips_privadas) ? {
    true    => $facts['networking']['ip'],
    default => $ips_privadas[0],
  }

  # 1. Recurso paquete: Apache debe estar instalado
  package { 'apache2':
    ensure => installed,
  }

  # 2. Recurso archivo: la página web se genera desde una plantilla con los facts
  file { '/var/www/html/index.html':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('webserver/index.html.epp', {
      'titulo'   => $titulo,
      'color'    => $color,
      'hostname' => $facts['networking']['hostname'],
      'ip'       => $ip,
      'sistema'  => "${facts['os']['name']} ${facts['os']['release']['full']}",
    }),
    require => Package['apache2'],
  }

  # 3. Recurso servicio: Apache debe estar encendido y arrancar con el sistema.
  #    Si la página cambia, Puppet reinicia el servicio (subscribe).
  service { 'apache2':
    ensure    => running,
    enable    => true,
    subscribe => File['/var/www/html/index.html'],
  }
}
