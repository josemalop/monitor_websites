<##############################################################################
Monitor de Websites v0.7 - Versión Servicio Funcional
(c)2025 Josema
##############################################################################>

# Configuración inicial
$global:logPath = Join-Path $PSScriptRoot "service.log"
$global:configPath = Join-Path $PSScriptRoot "config.ini"

# Función de logging mejorada
function Write-ServiceLog {
    param([string]$message, [string]$level="INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    Add-Content -Path $global:logPath -Value $logEntry
}

# Función para obtener procesos de usuario
function Get-UserProcesses {
    try {
        # Obtener la sesión activa
        $sessionInfo = quser | Where-Object { $_ -match '>' }
        if (-not $sessionInfo) {
            Write-ServiceLog "No se encontró sesión de usuario activa" "WARNING"
            return $null
        }

        $sessionId = ($sessionInfo -split '\s+')[2]
        $username = ($sessionInfo -split '\s+')[1]

        # Obtener procesos del usuario
        $processes = Get-Process -IncludeUserName | Where-Object {
            $_.SessionId -eq $sessionId -and $_.MainWindowTitle -ne ""
        }

        return @{
            Processes = $processes
            Username = $username
            SessionId = $sessionId
        }
    } catch {
        Write-ServiceLog "Error al obtener procesos: $_" "ERROR"
        return $null
    }
}

# Función principal de monitoreo
function Invoke-WebsiteMonitoring {
    param(
        [array]$websites,
        [int]$closeWindows,
        [int]$waitTime
    )

    $hostInfo = @{
        Hostname = $env:COMPUTERNAME
        IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
    }

    $userProcesses = Get-UserProcesses
    if (-not $userProcesses) { return }

    foreach ($site in $websites) {
        $matchingProcesses = $userProcesses.Processes | Where-Object { 
            $_.MainWindowTitle -match $site -or $_.ProcessName -match "chrome|firefox|edge|iexplore"
        }

        if ($matchingProcesses) {
            $logMessage = "Detección: Host: $($hostInfo.Hostname) | IP: $($hostInfo.IPAddress) | " +
                          "Usuario: $($userProcesses.Username) | Sitio: $site"
            
            Write-ServiceLog $logMessage

            # Registrar en el visor de eventos
            try {
                if (-not [System.Diagnostics.EventLog]::SourceExists("WebsiteMonitor")) {
                    New-EventLog -LogName "Application" -Source "WebsiteMonitor"
                }
                Write-EventLog -LogName "Application" -Source "WebsiteMonitor" -EventId 1001 -EntryType Information -Message $logMessage
            } catch {
                Write-ServiceLog "Error al escribir en EventLog: $_" "ERROR"
            }

            # Cerrar ventanas si está configurado
            if ($closeWindows -eq 1) {
                foreach ($proc in $matchingProcesses) {
                    try {
                        if (-not $proc.CloseMainWindow()) {
                            Stop-Process -Id $proc.Id -Force
                            Write-ServiceLog "Proceso $($proc.Name) forzado a cerrar (PID: $($proc.Id))"
                        } else {
                            Write-ServiceLog "Ventana $($proc.MainWindowTitle) cerrada correctamente"
                        }
                    } catch {
                        Write-ServiceLog "Error al cerrar proceso $($proc.Name): $_" "ERROR"
                    }
                }
            }
        }
    }
}

# Carga de configuración
function Get-ServiceConfig {
    try {
        if (-not (Test-Path $global:configPath)) {
            Write-ServiceLog "Archivo de configuración no encontrado" "ERROR"
            return $null
        }

        $config = @{
            Websites = @()
            WaitTime = 15
            CloseWindows = 0
            Debug = 0
        }

        $content = Get-Content $global:configPath
        foreach ($line in $content) {
            if ($line -match "^\s*Sitioweb\s*=\s*(.+)")) {
                $config.Websites += $matches[1].Trim()
            }
            elseif ($line -match "^\s*TiempoEspera\s*=\s*(\d+)")) {
                $config.WaitTime = [int]$matches[1]
            }
            elseif ($line -match "^\s*CerrarVentanas\s*=\s*(\d+)")) {
                $config.CloseWindows = [int]$matches[1]
            }
            elseif ($line -match "^\s*Debug\s*=\s*(\d+)")) {
                $config.Debug = [int]$matches[1]
            }
        }

        return $config
    } catch {
        Write-ServiceLog "Error al leer configuración: $_" "ERROR"
        return $null
    }
}

# Punto de entrada del servicio
try {
    Write-ServiceLog "=== Iniciando servicio de monitorización ==="

    while ($true) {
        $config = Get-ServiceConfig
        if ($config -and $config.Websites.Count -gt 0) {
            Invoke-WebsiteMonitoring -websites $config.Websites -closeWindows $config.CloseWindows -waitTime $config.WaitTime
        } else {
            Write-ServiceLog "Configuración inválida o no hay sitios para monitorizar" "WARNING"
        }

        Start-Sleep -Seconds ($config ? $config.WaitTime : 15)
    }
} catch {
    Write-ServiceLog "ERROR CRÍTICO: $_" "ERROR"
    Write-ServiceLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
} finally {
    Write-ServiceLog "=== Servicio detenido ==="
}