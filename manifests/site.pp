# Asegurar que el paquete de Apache (en Ubuntu se llama apache2) esté instalado
package { 'apache2':
  ensure => installed,
}

# Asegurar que el servicio de Apache esté ejecutándose y se inicie con el sistema
service { 'apache2':
  ensure     => running,
  enable     => true,
  subscribe  => File['/var/www/html/index.html'],
}

# Crear o modificar automáticamente la página web principal (demostrando idempotencia)
file { '/var/www/html/index.html':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "<html>
<head>
    <title>Laboratorio Puppet - Equipo</title>
</head>
<body style='font-family: Arial, sans-serif; text-align: center; margin-top: 50px;'>
    <h1 style='color: #2c3e50;'>¡Laboratorio de Puppet Completado con Éxito!</h1>
    <p>Este servidor fue configurado y automatizado utilizando <b>Puppet</b> y <b>Vagrant</b>.</p>
    <p><b>Integrantes:</b> Gerardo, Fidel e Irving.</p>
</body>
</html>\n",
}