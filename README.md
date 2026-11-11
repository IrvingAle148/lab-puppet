# Laboratorio de Automatización y Despliegue con Puppet

Práctica desarrollada por:
- **Gerardo Abraham Barron Gomez**
- **Fidel Cruz Reyes**
- **Irving Alejandro Seguin Luna**

> 📄 **Documentación completa:** [`docs/Documentacion_Lab_Puppet.docx`](docs/Documentacion_Lab_Puppet.docx) (marco teórico, explicación del código, procedimiento, solución de problemas, conclusiones y código fuente).

---

## Objetivo

Demostrar el uso de **Puppet** como herramienta de **Gestión de Configuración**: describimos en código cómo debe quedar un servidor web y Puppet lo configura solo, detecta cambios no autorizados y se **autorrepara** (idempotencia).

## Qué conceptos de la presentación se ven en la demo

| Concepto | Dónde se ve |
|---|---|
| **Recursos** | `package`, `file` y `service` en `modules/webserver/manifests/init.pp` |
| **Manifiestos** | `manifests/site.pp`, el archivo principal que Puppet ejecuta |
| **Clases** | `class webserver` agrupa los tres recursos bajo un nombre |
| **Módulos** | La carpeta `modules/webserver/` con su estructura estándar |
| **Hechos (Facts)** | La página muestra el nombre, la IP y el sistema del servidor, obtenidos con Facter |
| **Catálogo** | `puppet apply` compila el catálogo y lo aplica (mensaje *Compiled catalog…*) |
| **Idempotencia** | Ejecutar varias veces no cambia nada si el servidor ya está bien |
| **Reportes** | Archivo `last_run_report.yaml` con el resultado de cada ejecución |

> En producción, el catálogo lo compila un servidor central (**Puppet Master**) y lo envía a muchos agentes. En este laboratorio usamos `puppet apply` (modo standalone), que hace ese mismo trabajo dentro de la máquina: reúne los facts, compila el catálogo, lo aplica y genera el reporte.

---

## Estructura del proyecto

```
lab-puppet/
├── vagrantfile                           # Crea la VM e instala Puppet (fase de infraestructura)
├── manifests/
│   └── site.pp                           # Manifiesto principal
├── modules/
│   └── webserver/                        # Módulo
│       ├── manifests/init.pp             # Clase con los recursos
│       └── templates/index.html.epp      # Plantilla de la página (usa facts)
├── docs/
│   └── Documentacion_Lab_Puppet.docx     # Documentación en Word
└── README.md
```

---

## Cómo funciona el código

El laboratorio cubre dos fases del despliegue:

| Fase | Herramienta | Qué hace |
|---|---|---|
| 1. Aprovisionamiento de infraestructura | Vagrant + VirtualBox | Crea la VM Ubuntu 22.04 (`web01`, IP `192.168.56.11`) e instala Puppet 8 |
| 2. Gestión de configuración | Puppet (`puppet apply`) | Instala Apache, genera la página y mantiene el servicio encendido |

En un pipeline real seguiría una tercera fase: una herramienta de CI/CD (Jenkins, GitHub Actions) desplegaría la aplicación sobre el servidor ya preparado.

### `vagrantfile`
- Usa la box `ubuntu/jammy64`, 1.5 GB de RAM y 2 CPU, con red privada `192.168.56.11`.
- Comparte la carpeta del proyecto en `/vagrant`, así que lo que edites en tu computadora se ve dentro de la VM al instante.
- El aprovisionamiento espera a cloud-init, apaga servicios que bloquean `apt` (snapd, actualizaciones automáticas) e instala `puppet-agent` **solo si no está instalado**.
- Crea el atajo `aplicar` (`puppet apply --modulepath=/vagrant/modules /vagrant/manifests/site.pp`), que acepta parámetros extra como `--noop`.

### `manifests/site.pp`
Punto de entrada. Todo nodo (`node default`) recibe la clase `webserver` con dos parámetros: `titulo` y `color`. Cambiar el color y volver a aplicar demuestra que **basta con modificar el código** para cambiar el servidor.

### `modules/webserver/manifests/init.pp`
La clase agrupa tres recursos:

| Recurso | Estado deseado | Relación |
|---|---|---|
| `package { 'apache2' }` | Apache instalado | Se aplica primero |
| `file { '/var/www/html/index.html' }` | Página con dueño `root`, permisos `0644`, generada desde la plantilla | `require => Package['apache2']` |
| `service { 'apache2' }` | Encendido y habilitado al arranque | `subscribe => File[...]`: se reinicia si la página cambia |

Antes de los recursos, la clase revisa los facts de `networking.interfaces` para obtener la IP de la red `192.168.56.x` (si no la encuentra, usa la IP principal).

### `modules/webserver/templates/index.html.epp`
Plantilla EPP que recibe título, color, hostname, IP y sistema operativo, y genera el HTML. La página muestra datos reales del servidor obtenidos por Facter.

### Ciclo que ejecuta `aplicar`
1. **Facter** recopila los facts del servidor.
2. Puppet **compila el catálogo** a partir de `site.pp`, el módulo y los facts (*Compiled catalog for web01*).
3. Compara el estado real con el deseado y **aplica solo las diferencias**.
4. Guarda el **reporte** en `last_run_report.yaml`.

Es el mismo ciclo del modelo Master-Agent, pero todo ocurre dentro de la VM.

---

## Requisitos

| | Mínimo |
|---|---|
| Software | [VirtualBox](https://www.virtualbox.org/) y [Vagrant](https://developer.hashicorp.com/vagrant/downloads) |
| RAM libre | 1.5 GB (cierra otras VMs y programas pesados antes de `vagrant up`) |
| Disco libre | ~3 GB (imagen de Ubuntu ~0.7 GB, que se descarga una sola vez, + ~1.5 GB de la VM) |
| Internet | Solo la primera vez, para descargar Ubuntu, Puppet y Apache |

---

## Descargar el proyecto

**Opción A, con Git:**

```bash
git clone https://github.com/IrvingAle148/lab-puppet.git
cd lab-puppet
```

**Opción B, sin Git:** en la página del repositorio, botón verde **Code → Download ZIP**. Descomprime el archivo y abre una terminal (PowerShell o CMD) dentro de la carpeta `lab-puppet`.

---

## Paso 1: Levantar el entorno virtualizado

> Hazlo **antes** de la exposición: la primera vez tarda de 10 a 15 minutos.

```bash
vagrant up
```

Cuando termine debe aparecer `=== Puppet listo en web01 ===`. Luego entra al servidor:

```bash
vagrant ssh
```

El indicador cambia a `vagrant@web01:~$`: ya estás dentro del servidor Linux.

---

## Paso 2: Aplicar el manifiesto (estado deseado)

**2.1 Ver los facts:** los datos que Puppet conoce del servidor.

```bash
facter networking.hostname networking.interfaces.enp0s8.ip os.name
```

**2.2 Aplicar el código de Puppet:**

```bash
aplicar
```

> `aplicar` es un atajo que deja instalado el Vagrantfile. Equivale a:
> `sudo puppet apply --modulepath=/vagrant/modules /vagrant/manifests/site.pp`

Puppet compila el catálogo, instala Apache, crea la página y enciende el servicio. Abre en el navegador de tu computadora **http://192.168.56.11**: la página muestra el nombre, la IP y el sistema del servidor (facts).

---

## Paso 3: Simular una falla

Simulamos un error humano: alguien borra la página y apaga el servidor web.

```bash
sudo rm /var/www/html/index.html
sudo systemctl stop apache2
```

Recarga el navegador: la página ya no responde, el servidor salió del estado deseado.

Antes de corregir, pedimos a Puppet que solo **revise** (modo simulación):

```bash
aplicar --noop
```

Puppet indica lo que está mal (`would have…`) pero **no cambia nada**. Sirve para auditar.

---

## Paso 4: Restaurar con Puppet (autorreparación)

**4.1 Corregir:**

```bash
aplicar
```

Puppet recrea la página y vuelve a encender Apache. Recarga el navegador: el sitio regresa.

**4.2 Idempotencia:** ejecutar otra vez.

```bash
aplicar
```

Esta vez no aparece ningún cambio, porque el servidor ya está en el estado deseado.

**4.3 Cambiar el estado deseado:** en tu computadora, abre `manifests/site.pp` y cambia el color, por ejemplo:

```puppet
color  => '#7b2c2c',
```

Guarda el archivo, ejecuta `aplicar` en la VM y recarga el navegador: la página cambia sola. Basta con modificar el código; nadie edita el servidor a mano. Con un Puppet Master, ese mismo cambio llegaría a todos los servidores.

**4.4 Ver el reporte:**

```bash
sudo grep -E "status|title" /opt/puppetlabs/puppet/cache/state/last_run_report.yaml | head -20
```

Es el informe que Puppet genera en cada ejecución. Con un Puppet Master, este reporte se envía al servidor central.

---

## Apagar y liberar espacio

Para salir de la VM: `exit`.

| Comando | Qué hace |
|---|---|
| `vagrant halt` | Apaga la VM (conserva todo para la próxima vez) |
| `vagrant destroy -f` | Borra la VM y libera su espacio en disco |
| `vagrant box remove ubuntu/jammy64` | Borra también la imagen de Ubuntu (~0.7 GB). Solo si ya no la vas a usar |

---

## Solución de problemas

- **No abre la página en el navegador:** dentro de la VM ejecuta `curl localhost`. Si responde, revisa que VirtualBox tenga el adaptador *Host-Only* (192.168.56.x).
- **"The SSH connection was unexpectedly closed":** casi siempre es falta de espacio en el disco de tu computadora (VirtualBox pausa la VM). Libera espacio y ejecuta `vagrant reload --provision`.
- **`aplicar: command not found`:** sal de la VM y ejecuta `vagrant provision`.
