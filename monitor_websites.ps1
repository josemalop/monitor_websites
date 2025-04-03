<##############################################################################
Monitor de Websites v0.6
(c)2025 Josema
##############################################################################>

# El archivo de configuracion y el de log estaran en el mismo directorio que el script
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.ini"
$logFile = Join-Path -Path $PSScriptRoot -ChildPath "log.txt"

# Obtenemos el nombre del host donde se ejecuta el script
$hostname = hostname

# Obtenemos la direccion IP del equipo
$ipconfig = Get-NetIPConfiguration
$direccionIp = $ipconfig.IPv4Address.IPAddress

# Obtenemos el usuario que ha iniciado sesion en el equipo
$usuario = $env:USERNAME

# Valores por defecto
$debug = 0
$waitTime = 15
$sonar = 0
$frecSonido = 1000
$duracSonido = 1000
$websites = @()
$configmostrada = 0
$cerrarVentanas = 0

# Funcion para leer archivos INI simples
function Get-IniContent {
    param(
        [string]$filePath
    )
    
    $ini = @{}
    $section = "NO_SECTION"
    
    if (Test-Path $filePath) {
        $lines = Get-Content -Path $filePath
        
        foreach ($line in $lines) {
            $line = $line.Trim()
            
            # Ignoramos lineas vacias y comentarios
            if ($line -eq "" -or $line.StartsWith(";") -or $line.StartsWith("#")) {
                continue
            }
            
            # Seccion
            if ($line.StartsWith("[") -and $line.EndsWith("]")) {
                $section = $line.Substring(1, $line.Length - 2)
                $ini[$section] = @{}
                continue
            }
            
            # Clave=Valor
            $keyValue = $line -split "=", 2
            if ($keyValue.Count -eq 2) {
                $key = $keyValue[0].Trim()
                $value = $keyValue[1].Trim()
                
                # Creamos el arrays para las paginas a monitorizar
                if ($section -eq "Monitor" -and $key -eq "Sitioweb") {
                    if (-not $ini[$section][$key]) {
                        $ini[$section][$key] = @()
                    }
                    $ini[$section][$key] += $value
                } else {
                    $ini[$section][$key] = $value
                }
            }
        }
    }
    return $ini
}

# Bucle principal de monitorizacion
while ($true) {

    # Leemos la configuracion
    $iniContent = Get-IniContent -filePath $configFile

    if ($iniContent.ContainsKey("Monitor")) {
        $settings = $iniContent["Monitor"]

        # Vemos si estamos en modo debug
        if ($settings.ContainsKey("Debug")) {
            $debug = [int]$settings["Debug"]
        }
        
        # Obtenemos los segundos de espera entre comprobaciones
        if ($settings.ContainsKey("TiempoEspera")) {
            $waitTime = [int]$settings["TiempoEspera"]
        }
        
        # Obtenemos la frecuencia del sonido en Hz
        if ($settings.ContainsKey("FrecSonido")) {
            $frecSonido = [int]$settings["FrecSonido"]
        }

        # Obtenemos si debe sonar el script o no
        if ($settings.ContainsKey("Sonar")) {
            $sonar = [int]$settings["Sonar"]
        }

        # Obtenemos la duracion del sonido en ms
        if ($settings.ContainsKey("DuracSonido")) {
            $duracSonido = [int]$settings["DuracSonido"]
        }

        # Obtenemos las paginas a monitorizar
        if ($settings.ContainsKey("Sitioweb")) {
            $websites = $settings["Sitioweb"]
        }

        # Obtenemos si se tienen que cerrar las ventanas detectadas
        if ($settings.ContainsKey("CerrarVentanas")) {
            $cerrarVentanas = [int]$settings["CerrarVentanas"]
        }
    }

    # Mostramos la configuracion cargada si la variable debug es 1
    if ( $debug -eq 1 -and $configmostrada -eq 0 ) {
        Write-Host "Configuracion cargada:"
        Write-Host "Tiempo de espera: $waitTime segundos."
        Write-Host "$(if ($sonar -eq 1) {"Se reproducira un sonido de $frecSonido Hz con una duracion de $duracSonido ms."} else {"No se reproducira ningun sonido."})"
        Write-Host "$(if ($cerrarVentanas -eq 1) {'Se cerraran las ventanas destectadas.'} else {'No se cerraran las ventanas destectadas.'})"
        Write-Host "Sitios web a monitorizar:"
        $websites | ForEach-Object { Write-Host "- $_" }
        $configmostrada = 1
    } 
    
    if ($debug -eq 0 ) {
        clear
        $configmostrada = 0
    }


    # Obtenemos los procesos con ventanas abiertas
    $processes = Get-Process | Where-Object { $_.MainWindowTitle -ne "" }

    # Verificamos cada sitio web en los títulos de ventana
    foreach ($site in $websites) {
        $matchingProcesses = $processes | Where-Object { $_.MainWindowTitle -match $site }
        
        if ($matchingProcesses) {
            # Emitimos un sonido usando el PC speaker
            if ($sonar -eq 1) {
                [console]::Beep($frecSonido, $duracSonido)
            }

            # Registramos la fecha, hora y el sitio web en el archivo de log
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $mensaje = "Equipo: $hostname - IP: $direccionIp - Usuario: $usuario - Web: $site - Accion: $(if ($cerrarVentanas -eq 1) {'Ventana cerrada'} else {'Detectada'})"
            $logMessage = "[$timestamp] - $mensaje"
            Add-Content -Path $logFile -Value $logMessage
            
            # Verificamos/creamos la fuente de eventos
            if (-not [System.Diagnostics.EventLog]::SourceExists("MonitorWebsites")) {
                New-EventLog -LogName "Application" -Source "MonitorWebsites"
            }

            # Escribimos en el Visor de Eventos
            Write-EventLog -LogName "Application" -Source "MonitorWebsites" -EntryType "Information" -EventId 1 -Message $mensaje

            # Opcional: Mostramos en la consola
            if ($debug -eq 1) {
                Write-Host "Alerta: $logMessage"
            }

            # Cerramos ventanas si esta activada la opcion
            if ($cerrarVentanas -eq 1) {
                foreach ($proc in $matchingProcesses) {
                    try {
                        $proc.CloseMainWindow() | Out-Null
                        Start-Sleep -Milliseconds 500
                        if (!$proc.HasExited) {
                            $proc | Stop-Process -Force
                        }
                        if ($debug -eq 1) {
                            Write-Host "Ventana cerrada: $($proc.MainWindowTitle)" -ForegroundColor Red
                        }
                    } catch {
                        if ($debug -eq 1) {
                            Write-Host "Error al cerrar ventana: $_" -ForegroundColor Yellow
                        }
                    }
                }
            }
        }
    }

    # Esperamos el tiempo especificado antes de la siguiente comprobacion
    Start-Sleep -Seconds $waitTime
}
