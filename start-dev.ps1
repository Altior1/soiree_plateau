#!/usr/bin/env pwsh
# Charge .env puis lance `iex -S mix phx.server`
# Usage : .\start-dev.ps1   (ou : pwsh -File .\start-dev.ps1)

param(
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EnvFile))
{
    Write-Warning "$EnvFile introuvable — démarrage avec les defaults de config/dev.exs"
} else
{
    Write-Host "Chargement de $EnvFile..." -ForegroundColor Cyan
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$')
        { return
        }
        $name, $value = $_.Split('=', 2)
        if (-not $value)
        { return
        }
        $value = $value.Trim().Trim('"').Trim("'")
        $name = $name.Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
        Write-Host "  $name=$value"
    }
}

Write-Host "Lancement de iex -S mix phx.server..." -ForegroundColor Green
iex.bat -S mix phx.server
