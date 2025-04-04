# Monitor de Websites
## &copy;2025 Josema

Script que monitoriza ventanas abiertas alertando y/o cerrando la ventana implicada con el texto especificado en el t&iacute;tulo. Cre&eacute; este script con la idea de controlar y/o restringir el uso de la IA en las aulas de inform&aacute;tica. Usa este script bajo tu propia responsabilidad.

La configuraci&oacute;n de los distintos parametros se realiza con un fichero `config.ini` ubicado en la misma ruta del script y no es preciso reiniciar nada si se modifica este archivo ya que se relee de forma autom&aacute;tica, facilitando as&iacute; las modificaciones. Lo ideal es que el aula est&eacute; configurada de forma que se pueda distribuir el fichero de configuraci&oacute;n desde el ordenador del profesor con un `robocopy` o similar.

### Changelog:
- **v0.1**. Versi&oacute;n inicial.
- **v0.2**. La configuraci&oacute;n se relee de forma autom&aacute;tica.
- **v0.3**. Se incluye el modo debug.
- **v0.4**. Se documenta mejor el c&oacute;digo.
    - Se mejoran los mensajes del modo debug.
    - Se modifica el texto a grabar en el log.
    - Se incluye la escritura del mensaje en el visor de eventos.
- **v0.5**. Se mejora la salida del modo debug.
- **v0.6**. Se incluye opci&oacute;n para cerrar las ventanas detectadas. **Ojo, no se cierra la pesta&ntilde;a afectada, sino la ventana completa del navegador.**

### Pruebas de ejecuci&oacute;n

Para probar la ejecuci&oacute;n del script, tienes que abrir una ventana de **Powershell** como administrador del equipo y ejecutar:
`Set-ExecutionPolicy -ExecutionPolicy Bypass`

### Descripci&oacute;n de las monitorizaciones.

Cada vez que se detecte que hay una ventana o pesta&ntilde;a abierta cuyo t&iacute;tulo coincida con alg&uacute;n valor de los definidos en el array *"Sitioweb"*, se grabar&aacute;:

- Una l&iacute;nea en un fichero de log `log.txt`ubicado en la misma ruta del script.
- Un evento en el visor de eventos con el contenido de la alerta.

El formato de mensaje es: `Equipo: nombre_equipo - IP: direccion IP - Usuario: Usuario conectado al equipo - Web: Sitioweb detectado - Accion: Ventana cerrada/Detectada`.

En el fichero de log todos los mensajes ir&aacute;n precedidos de un `timestamp`.

### Descripci&oacute;n de los parametros del fichero `config.ini`.

- **Debug**. *Por defecto a 0*. Si vale 1, se mostrar&aacute;n los valores configurados y las alertas por pantalla.
- **TiempoEspera**. *Por defecto a 15*. Tiempo de espera en segundos entre cada monitorizaci&oacute;n.
- **Sonar**. *Por defecto a 0*. Si vale 1, el altavoz del PC emitira un sonido en cada alerta.
- **CerrarVentanas**. *Por defecto a 0*. Si vale 1, se cierra la ventana detectada.
- **FrecSonido**. *Por defecto a 1000*. La frecuencia del sonido en Herzios.
- **DuracSonido**. *Por defecto a 1000*. La duraci&oacute;n del sonido en milisegundos.
- **Sitioweb**. *Por defecto vacio*. Este campo se puede repetir, sirve para crear un array con los sitios a monitorizar.

### Convertir el script a servicio de Windows. AVISO: ¡¡¡Al convertir el script a servicio, no funciona todav&iacute;a!!!

**1. Instalar Chocolatey y NSSM**

- Instala **Chocolatey** ejecutando lo siguiente desde una ventana de **Powershell** como administrador del equipo: `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`.
- En la misma ventana de **Powershell**, instala **nssm** ejecutando: `choco -y install nssm`.

**2. Preparar el script de PowerShell**

- Aseg&uacute;rate de que el script de PowerShell est&eacute; guardado en una ubicaci&oacute;n permanente (por ejemplo, `C:\scripts\monitor_websites.ps1`). 
- El script debe tener permisos de ejecuci&oacute;n en el sistema. 
- Debemos asegurarnos de que no tenga acceso al directorio quien no debe.

**3. Crear el servicio con NSSM**

- Abre una ventana de Command Prompt (`cmd`) o PowerShell como administrador.
- Ejecuta el siguiente comando para abrir la interfaz gr&aacute;fica de NSSM: `nssm install MonitorWebsites` (Reemplaza *MonitorWebsites* con el nombre que desees para tu servicio).
- En la ventana "NSSM service installer" que aparecer&aacute;, configura los siguientes campos:
    - En la pesta&ntilde;a **Application**:
        - **Path**: Ruta al ejecutable de PowerShell. Normalmente es: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` (busca la ruta correcta en tu sistema).
        - **Startup directory**: Ruta a la carpeta donde est&aacute; el script. Por ejemplo: `C:\scripts`
        - **Arguments**: Argumentos para ejecutar el script. Por ejemplo: `-ExecutionPolicy Bypass -File "C:\scripts\monitor_websites.ps1"`
    - En la pesta&ntilde;a **Log on**:
        - **This account**: Introduce el usuario administrador del equipo (normalmente ser&aacute; "Administrador" o "Administrator").
        - **Password**: La contrase&ntilde;a del usuario administrador (hay que ponerla dos veces).
- Haz clic en **Install service**. Esto crear&aacute; el servicio en Windows.

**4. Configurar el servicio (opcional)**

- Abre el Administrador de servicios de Windows:
- Presiona Win + R, escribe services.msc`` y presiona Enter.
- Busca el servicio que acabas de crear (por ejemplo, *MonitorWebsites*).
- Haz clic derecho sobre el servicio y selecciona Propiedades.
    - En la pesta&ntilde;a **General**, configura el **Tipo de inicio** a: *"Autom&aacute;tico"* para que el servicio se inicie con Windows.
    - En la pesta&ntilde;a **Recuperaci&oacute;n**, configura para todos los errores **Reiniciar el servicio** para que el servicio se reinicie si hay alg&uacute;n fallo.
- Haz clic en **Aplicar**, ve a la pesta&ntilde;a **General**, pulsa en **Iniciar** y luego en **Aceptar**.

**5. Iniciar y probar el servicio**

- En el Administrador de servicios, haz clic derecho sobre tu servicio y selecciona **Iniciar**.
- Verifica que el servicio est&eacute; en ejecuci&oacute;n y que est&eacute; realizando las acciones esperadas (por ejemplo, emitir un sonido si se abre una p&aacute;gina web monitorizada).

**6. Detener o eliminar el servicio (si es necesario)**

- Detener el servicio: En el Administrador de servicios, haz clic derecho sobre el servicio y selecciona **Detener**.
- Eliminar el servicio:
    - Abre una ventana de Command Prompt (`cmd`) o PowerShell como administrador.
    - Ejecuta el siguiente comando: `nssm remove MonitorWebsites confirm` (Reemplaza MonitorWebsites con el nombre de tu servicio).
