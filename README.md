# Monitor de Websites
## (c)2025 Josema

Script que monitoriza ventanas abiertas y alerta si encuentra ventanas con el
texto especificado.

La configuracion de los distintos parametros se realiza en el fichero de configuracion
`config.ini` y no es preciso reiniciar el script si se modifica, se relee de forma
automatica.

Descripcion de los parametros del fichero `config.ini`:

- **Debug**. *Por defecto a 0*. Si vale 1, se mostraran mensajes y alertas por pantalla.
- **TiempoEspera**. *Por defecto a 15*. Tiempo de espera en segundos entre cada monitorizacion.
- **Sonar**. *Por defecto a 1*. Si vale 1, el altavoz del PC emitira un sonido en cada alerta.
- **FrecSonido**. *Por defecto a 1000*. La frecuencia del sonido en Herzios.
- **DuracSonido**. *Por defecto a 1000*. La duracion del sonido en milisegundos.
- **Sitioweb**. *Por defecto vacio*. Este campo se puede repetir, sirve para crear un array con los sitios a monitorizar.

### Changelog:
- **v0.1**. Version inicial.
- **v0.2**. La configuracion se relee de forma automatica.
- **v0.3**. Se incluye el modo debug.
- **v0.4**. Se documenta mejor el codigo.
    - Se mejoran los mensajes del modo debug.
    - Se modifica el texto a grabar en el log.
    - Se incluye la escritura del mensaje en el visor de eventos.
- **v0.5**. Se mejora la salida del modo debug.
