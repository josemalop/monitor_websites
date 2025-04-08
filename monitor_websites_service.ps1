<##############################################################################
Monitor de Websites v0.7 - Versión para Servicio Windows
(c)2025 Josema
##############################################################################>

# Configuración de logging
$logDirectory = "C:\Logs\WebsiteMonitor"
$logFile = Join-Path -Path $logDirectory -ChildPath "website_monitor.log"
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.ini"

# Crear directorio de logs si no existe
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

# Iniciar logging
Start-Transcript -Path $logFile -Append -IncludeInvocationHeader

# Función para escribir en el log
function Write-ServiceLog {
    param(
        [string]$message,
        [string]$level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Función para leer archivos INI
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
            
            if ($line -eq "" -or $line.StartsWith(";") -or $line.StartsWith("#")) {
                continue
            }
            
            if ($line.StartsWith("[") -and $line.EndsWith("]")) {
                $section = $line.Substring(1, $line.Length - 2)
                $ini[$section] = @{}
                continue
            }
            
            $keyValue = $line -split "=", 2
            if ($keyValue.Count -eq 2) {
                $key = $keyValue[0].Trim()
                $value = $keyValue[1].Trim()
                
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

# Función para obtener el usuario activo
function Get-ActiveUser {
    try {
        $session = quser | Where-Object { $_ -match '^\s*>' -or $_ -match '^\s* ' }
        if ($session) {
            $sessionParts = $session -split '\s+'
            return $sessionParts[1]
        }
        return "SYSTEM"
    } catch {
        return "UNKNOWN"
    }
}

# Función principal de monitoreo
function Start-WebsiteMonitoring {
    param(
        [int]$waitTime,
        [array]$websites,
        [int]$cerrarVentanas,
        [int]$debug
    )
    
    $hostname = hostname
    $ipconfig = Get-NetIPConfiguration
    $direccionIp = $ipconfig.IPv4Address.IPAddress
    $usuario = Get-ActiveUser

    # Obtenemos los procesos con ventanas abiertas del usuario activo
    try {
        $activeSessionId = (Get-Process -Name explorer -IncludeUserName).SessionId | Select-Object -First 1
        $processes = Get-Process -IncludeUserName | Where-Object { 
            $_.SessionId -eq $activeSessionId -and $_.MainWindowTitle -ne "" 
        }
    } catch {
        Write-ServiceLog "Error al obtener procesos: $_" -level "ERROR"
        return
    }

    foreach ($site in $websites) {
        $matchingProcesses = $processes | Where-Object { $_.MainWindowTitle -match $site }
        
        if ($matchingProcesses) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $mensaje = "Equipo: $hostname - IP: $direccionIp - Usuario: $usuario - Web: $site - Accion: $(if ($cerrarVentanas -eq 1) {'Ventana cerrada'} else {'Detectada'})"
            
            Write-ServiceLog $mensaje
            
            # Escribimos en el Visor de Eventos
            if (-not [System.Diagnostics.EventLog]::SourceExists("MonitorWebsites")) {
                New-EventLog -LogName "Application" -Source "MonitorWebsites"
            }
            Write-EventLog -LogName "Application" -Source "MonitorWebsites" -EntryType "Information" -EventId 1 -Message $mensaje

            if ($cerrarVentanas -eq 1) {
                foreach ($proc in $matchingProcesses) {
                    try {
                        $proc.CloseMainWindow() | Out-Null
                        Start-Sleep -Milliseconds 500
                        if (!$proc.HasExited) {
                            $proc | Stop-Process -Force
                        }
                        Write-ServiceLog "Ventana cerrada: $($proc.MainWindowTitle)"
                    } catch {
                        Write-ServiceLog "Error al cerrar ventana: $_" -level "ERROR"
                    }
                }
            }
        }
    }
}

# Bucle principal del servicio
try {
    Write-ServiceLog "Iniciando servicio de monitorización de websites"
    
    # Valores por defecto
    $debug = 0
    $waitTime = 15
    $websites = @()
    $cerrarVentanas = 0
    $configLoaded = $false

    while ($true) {
        # Leemos la configuración
        $iniContent = Get-IniContent -filePath $configFile

        if ($iniContent.ContainsKey("Monitor")) {
            $settings = $iniContent["Monitor"]

            $debug = [int]($settings["Debug"] ?? 0)
            $waitTime = [int]($settings["TiempoEspera"] ?? 15)
            $cerrarVentanas = [int]($settings["CerrarVentanas"] ?? 0)
            
            if ($settings.ContainsKey("Sitioweb")) {
                $websites = $settings["Sitioweb"]
            }

            if (-not $configLoaded) {
                Write-ServiceLog "Configuración cargada:"
                Write-ServiceLog "Tiempo de espera: $waitTime segundos"
                Write-ServiceLog "Cerrar ventanas: $(if ($cerrarVentanas -eq 1) {'Activado'} else {'Desactivado'})"
                Write-ServiceLog "Sitios web a monitorizar: $($websites -join ', ')"
                $configLoaded = $true
            }
        } else {
            Write-ServiceLog "No se encontró la sección Monitor en el archivo de configuración" -level "WARNING"
        }

        if ($websites.Count -gt 0) {
            Start-WebsiteMonitoring -waitTime $waitTime -websites $websites -cerrarVentanas $cerrarVentanas -debug $debug
        } else {
            Write-ServiceLog "No hay sitios web configurados para monitorizar" -level "WARNING"
        }

        Start-Sleep -Seconds $waitTime
    }
} catch {
    Write-ServiceLog "Error crítico en el servicio: $_" -level "ERROR"
    throw
} finally {
    Write-ServiceLog "Servicio de monitorización detenido"
    Stop-Transcript
}
