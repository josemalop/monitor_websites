# Monitor de Websites
## &copy;2025 Josema

### Changelog:
- **v0.1**. Versi&oacute;n inicial.
- **v0.2**. La configuraci&oacute;n se relee de forma autom&aacute;tica.
- **v0.3**. Se incluye el modo debug.
- **v0.4**. Se documenta mejor el c&oacute;digo.
    - Se mejoran los mensajes del modo debug.
    - Se modifica el texto a grabar en el log.
    - Se incluye la escritura del mensaje en el visor de eventos.
- **v0.5**. Se mejora la salida del modo debug.

Script que monitoriza ventanas abiertas y alerta si encuentra ventanas con el
texto especificado.

La configuraci&oacute;n de los distintos parametros se realiza en el fichero de configuraci&oacute;n `config.ini` y no es preciso reiniciar el script si se modifica, se relee de forma autom&aacute;tica.

### Descripci&oacute;n de las monitorizaciones.
Cada vez que se detecte que hay una ventana o pesta&ntilde;a abierta cuyo t&iacute;tulo coincida con alg&uacute;n valor de los definidos en el array "Sitioweb", se grabar&aacute;:
- Una l&iacute;nea en un fichero de log `log.txt`ubicado en la misma ruta del script.
- Un evento en el visor de eventos con el contenido de la alerta.

El formato de mensaje es: `Equipo: nombre_equipo - IP: direcc&oacute;n IP - Usuario: Usuario conectado al equipo - Web: Sitioweb detectado`.

En el fichero de log todos los mensajes ir&acute;n precedidos de un `timestamp`.

### Descripci&oacute;n de los parametros del fichero `config.ini`.
- **Debug**. *Por defecto a 0*. Si vale 1, se mostrar&aacute;n los valores configurados y las alertas por pantalla.
- **TiempoEspera**. *Por defecto a 15*. Tiempo de espera en segundos entre cada monitorizaci&oacute;n.
- **Sonar**. *Por defecto a 1*. Si vale 1, el altavoz del PC emitira un sonido en cada alerta.
- **FrecSonido**. *Por defecto a 1000*. La frecuencia del sonido en Herzios.
- **DuracSonido**. *Por defecto a 1000*. La duraci&oacute;n del sonido en milisegundos.
- **Sitioweb**. *Por defecto vacio*. Este campo se puede repetir, sirve para crear un array con los sitios a monitorizar.

