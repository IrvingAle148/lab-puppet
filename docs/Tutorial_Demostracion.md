# Tutorial de demostración: Laboratorio de Automatización con Puppet

Guía para ejecutar la práctica en vivo durante la exposición.
Duración sugerida: **10 a 12 minutos** (los pasos marcados con ⭐ son el núcleo; el resto se puede omitir si hay poco tiempo).

| Dato | Valor |
|---|---|
| Servidor | `web01`, Ubuntu 22.04, IP `192.168.56.11` |
| Página web | http://192.168.56.11 |
| Herramientas | Vagrant 2.4.9 + VirtualBox 7.2 (ya instalados en este equipo) |
| Comando central | `aplicar` (atajo de `puppet apply`) |

---

## 0. Antes de la exposición (checklist)

La demostración **no se improvisa**: la máquina virtual ya debe estar creada y funcionando.

**La noche anterior o al menos 20 minutos antes:**

1. Abrir una terminal (PowerShell o Git Bash) en `C:\Users\USER\Desktop\lab-puppet`.
2. Levantar la VM (la primera vez tarda 10–15 min; las siguientes, menos de 1 min):

   ```bash
   vagrant up
   ```

   Debe terminar con `=== Puppet listo en web01 ===`.
3. Comprobar que la página responde. En el navegador: **http://192.168.56.11**
   (si aún no se ejecutó Puppet, puede dar error: eso se resuelve en el Paso 2 de la demo).
4. Dejar estas tres ventanas listas y visibles:
   - **Terminal** en la carpeta del proyecto.
   - **Navegador** con http://192.168.56.11 abierto.
   - **Editor de código** con `manifests/site.pp` abierto (se edita en vivo en el Paso 7).
5. Ejecutar `vagrant status`: debe decir `running (virtualbox)`.
6. Cerrar programas pesados (navegadores con muchas pestañas, otras VM, juegos): la VM usa 1.5 GB de RAM.

> **Regla de oro:** nunca ejecutes `vagrant destroy` antes de exponer. Borra la máquina y habría que esperar 15 minutos a reconstruirla.

---

## 1. Apertura: qué vamos a demostrar (30 segundos)

Frase para iniciar:

> "Vamos a demostrar la **gestión de configuración** con Puppet. En lugar de configurar un servidor a mano, describimos en código cómo debe quedar —Apache instalado, una página web y el servicio encendido— y Puppet lo lleva a ese estado solo. Además, si alguien rompe el servidor, Puppet lo **autorrepara**, y si ya está bien, **no cambia nada** (idempotencia)."

Muestra rápida de la estructura (opcional, 20 segundos):

```bash
ls -R manifests modules
```

> "`vagrantfile` crea la infraestructura; `manifests/site.pp` es el punto de entrada; `modules/webserver` es el módulo con la clase y la plantilla de la página."

---

## 2. ⭐ Entrar al servidor y ver los facts

```bash
vagrant ssh
```

El indicador cambia a `vagrant@web01:~$`: ya estás **dentro** del servidor Linux (no en Windows).

Mostrar los datos que Puppet conoce del servidor:

```bash
facter networking.hostname networking.interfaces.enp0s8.ip os.name
```

Salida esperada (aproximada):

```
web01
192.168.56.11
Ubuntu
```

> "Estos son los **facts**: información que Facter recopila del propio servidor (nombre, IP, sistema operativo). La página web que veremos se construye con estos datos, no están escritos a mano."

*Si el comando diera vacío por el nombre de la interfaz, usar `facter networking` y señalar la IP `192.168.56.11`.*

---

## 3. ⭐ Aplicar el manifiesto (el corazón de la demo)

```bash
aplicar
```

> "`aplicar` es un atajo del `vagrantfile` que ejecuta:
> `sudo puppet apply --modulepath=/vagrant/modules /vagrant/manifests/site.pp`.
> En producción esto lo haría un **Puppet Master**; aquí lo hacemos en modo standalone."

Mientras corre, ir señalando la salida en voz alta:

| Lo que aparece | Qué explicar |
|---|---|
| `Compiled catalog for web01` | Puppet leyó el manifiesto + los facts y armó el **catálogo**: la lista de lo que debe existir. |
| `Package[apache2]/ensure: created` | **Recurso package**: Apache se instaló. |
| `File[/var/www/html/index.html]/content: content changed` | **Recurso file**: la página se generó desde la plantilla EPP. |
| `Service[apache2]: Triggered 'refresh'` | **Recurso service**: Apache arrancó y quedó habilitado. |
| `Applied catalog in ... seconds` | El catálogo se aplicó por completo. |

**Verificación en vivo:** cambiar a la ventana del navegador y recargar **http://192.168.56.11**.

> "La página muestra el nombre del servidor, su IP y el sistema operativo: son los facts que acabamos de ver, insertados por la plantilla. También muestra el título y el color, que vienen del manifiesto `site.pp`."

Puntos a nombrar señalando la página:
- `webserver` es una **clase** que agrupa los tres recursos.
- `require => Package['apache2']` garantiza el orden: primero el paquete, luego el archivo.
- `subscribe => File[...]` hace que Apache se reinicie **solo si** la página cambia.

---

## 4. ⭐ Simular una falla (error humano)

De vuelta en la terminal de la VM:

```bash
sudo rm /var/www/html/index.html
sudo systemctl stop apache2
```

Recargar el navegador: la página ya **no responde** (error de conexión).

> "Alguien borró la página y apagó el servicio: el servidor salió del estado deseado. Así se ve un servidor que se administra a mano."

---

## 5. ⭐ Auditar sin cambiar nada (`--noop`)

```bash
aplicar --noop
```

Salida esperada: mensajes con **`would have`** / **`(noop)`**, por ejemplo
`File[...]/ensure: current_value absent, should be file (noop)`.

> "El modo `--noop` es una **simulación**: Puppet detecta y reporta exactamente qué está mal, pero no toca nada. Sirve para auditar sin riesgo."

Recargar el navegador: **sigue caído**. Eso demuestra que solo revisó.

---

## 6. ⭐ Autorreparación e idempotencia

**6.1 Reparar:**

```bash
aplicar
```

Puppet recrea la página y vuelve a encender Apache. Recargar el navegador: **el sitio regresa**.

> "Nadie escribió la página otra vez ni encendió el servicio a mano: Puppet comparó el estado real con el deseado y aplicó solo las diferencias."

**6.2 Ejecutar de nuevo (idempotencia):**

```bash
aplicar
```

Esta vez **no aparece ningún recurso modificado**: solo la compilación y el cierre.

> "Esta es la **idempotencia**: aplicarlo dos, diez o cien veces da el mismo resultado. La segunda ejecución no cambia nada porque el servidor ya está como debe estar. Por eso Puppet se puede ejecutar cada 30 minutos sin miedo."

---

## 7. ⭐ Cambiar el estado deseado (el cierre fuerte)

1. En **Windows**, en el editor, abrir `manifests/site.pp`.
2. Cambiar el color, por ejemplo:

   ```puppet
   color  => '#7b2c2c',
   ```

3. Guardar (la carpeta está compartida en `/vagrant`, así que el cambio se ve al instante en la VM).
4. En la VM:

   ```bash
   aplicar
   ```

5. Recargar el navegador: **la página cambia de color sola**.

> "Bastó con modificar una línea de código. Nadie entró al servidor a editar el HTML. Ese es el poder de la gestión de configuración: el código es la única fuente de verdad, y con un Puppet Master el mismo cambio llegaría a cientos de servidores a la vez."

> **Tip:** si el navegador no muestra el cambio, recargar con `Ctrl + F5` (caché).

**Restaurar el color original** para dejar el proyecto como estaba:

```puppet
color  => '#1f4e79',
```

Guardar y ejecutar `aplicar` otra vez.

---

## 8. Ver el reporte de la ejecución

```bash
sudo grep -E "status|title" /opt/puppetlabs/puppet/cache/state/last_run_report.yaml | head -20
```

> "Cada ejecución deja un **reporte** con el resultado. En un entorno con Puppet Master, ese reporte se envía al servidor central para auditar todos los nodos desde un solo lugar."

---

## 9. Cierre de la demostración (30 segundos)

> "Resumimos: **Vagrant** aprovisionó la infraestructura y **Puppet** gestionó la configuración. Vimos los tres recursos (paquete, archivo, servicio), los facts, el catálogo, la detección de una falla, la autorreparación y la idempotencia. La conclusión es que el servidor deja de configurarse a mano: se describe en código, se versiona con Git y se puede reproducir igual cuantas veces haga falta."

Salir de la VM sin apagarla:

```bash
exit
```

---

## 10. Modo pánico: todo en orden, para copiar y pegar

Si algo se desordena durante la demo, esta es la secuencia completa desde Windows:

```bash
# 1. (Solo si la VM está apagada; tarda 1 min)
vagrant up

# 2. Entrar al servidor
vagrant ssh
```

Ya dentro de la VM:

```bash
facter networking.hostname networking.interfaces.enp0s8.ip os.name
aplicar
# -> revisar http://192.168.56.11 en el navegador

sudo rm -f /var/www/html/index.html
sudo systemctl stop apache2
# -> recargar: caído

aplicar --noop
# -> "would have ... (noop)", no repara

aplicar
# -> recargar: página de vuelta

aplicar
# -> sin cambios: idempotencia

sudo grep -E "status|title" /opt/puppetlabs/puppet/cache/state/last_run_report.yaml | head -20
exit
```

---

## 11. Preguntas probables del jurado

| Pregunta | Respuesta corta |
|---|---|
| ¿Qué es Puppet? | Herramienta de gestión de configuración: describes el estado deseado en código y ella lo aplica y lo mantiene. |
| ¿Qué es un recurso? | La unidad mínima de configuración: un paquete, un archivo, un servicio. Aquí usamos tres. |
| ¿Qué es un manifiesto? | El archivo donde se declara el estado deseado; `site.pp` es el punto de entrada. |
| ¿Qué es una clase? | Un grupo con nombre de recursos relacionados; aquí `webserver` agrupa paquete, archivo y servicio. |
| ¿Qué es un módulo? | La carpeta con estructura estándar (`manifests/`, `templates/`) que contiene la clase reutilizable. |
| ¿Qué es un fact? | Dato que Facter obtiene del servidor (nombre, IP, SO); se usa para generar la página. |
| ¿Qué es el catálogo? | El resultado de compilar el manifiesto con los facts: la lista concreta de recursos a aplicar. |
| ¿Qué es idempotencia? | Aplicar el mismo código varias veces deja el mismo resultado; si ya está bien, no hace nada. |
| ¿Qué diferencia hay entre `require` y `subscribe`? | `require` ordena (primero paquete, luego archivo); `subscribe` reinicia el servicio si el archivo cambia. |
| ¿Por qué `puppet apply` y no Master-Agent? | Es un laboratorio de una sola máquina; `apply` hace el mismo ciclo (facts → catálogo → aplicación → reporte) localmente. En producción, el Master compila y los agentes aplican. |
| ¿Dónde se ve una falla y su reparación? | Al borrar la página y apagar Apache: `--noop` la reporta y `apply` la corrige. |
| ¿Se puede versionar? | Sí, todo el proyecto está en Git; la configuración del servidor se audita y se replica como código. |

---

## 12. Problemas durante la demo y solución rápida

| Síntoma | Solución |
|---|---|
| `vagrant up` dice que la VM ya está corriendo | Normal, sigue con `vagrant ssh`. |
| La página no abre en el navegador | Dentro de la VM: `curl localhost`. Si responde, el problema es de red del host: revisar el adaptador **Host-Only** de VirtualBox (`192.168.56.x`). |
| "The SSH connection was unexpectedly closed" | Suele ser falta de espacio en disco (VirtualBox pausa la VM). Liberar espacio y `vagrant reload --provision`. |
| `aplicar: command not found` | Salir (`exit`) y ejecutar `vagrant provision`. |
| Cambié el color y no se ve | `Ctrl + F5` en el navegador; luego `aplicar` de nuevo. |
| Error de sintaxis al editar `site.pp` | Revisar comas y comillas; deshacer el cambio con `Ctrl + Z` y guardar. |
| Puppet tarda mucho | Es normal la primera vez (descarga Apache). Después tarda segundos. |
| La VM quedó en `poweroff` | `vagrant up` y esperar el mensaje `=== Puppet listo en web01 ===`. |

---

## 13. Después de la exposición

| Comando (en Windows, en la carpeta del proyecto) | Qué hace |
|---|---|
| `vagrant halt` | Apaga la VM y conserva todo para la próxima. **Recomendado.** |
| `vagrant destroy -f` | Borra la VM y libera ~1.5 GB. |
| `vagrant box remove ubuntu/jammy64` | Borra también la imagen de Ubuntu (~0.7 GB). Solo si ya no se usará. |

---

*Documentación teórica completa (marco teórico, explicación del código, procedimiento, conclusiones y código fuente): `docs/Documentacion_Lab_Puppet.docx`.*
