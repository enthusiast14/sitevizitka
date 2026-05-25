$port = 5000
$localCloudflared = Join-Path $env:LOCALAPPDATA "Programs\cloudflared\cloudflared.exe"
$cloudflaredCmd = $null
$venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$pythonCmd = $null
$shellExe = (Get-Process -Id $PID).Path

if (Test-Path $venvPython) {
    $pythonCmd = $venvPython
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} else {
    Write-Host "Python не найден." -ForegroundColor Red
    Write-Host "Установите Python и снова запустите этот файл." -ForegroundColor Yellow
    Read-Host "Нажмите Enter, чтобы закрыть окно"
    exit 1
}

if (Get-Command cloudflared -ErrorAction SilentlyContinue) {
    $cloudflaredCmd = "cloudflared"
} elseif (Test-Path $localCloudflared) {
    $cloudflaredCmd = $localCloudflared
} else {
    Write-Host "Не найден cloudflared." -ForegroundColor Red
    Write-Host "1. Установите cloudflared" -ForegroundColor Yellow
    Write-Host "2. Затем снова запустите этот файл" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "После установки будет создана публичная ссылка для преподавателя." -ForegroundColor Cyan
    Read-Host "Нажмите Enter, чтобы закрыть окно"
    exit 1
}

Write-Host "Запуск локального сервера Flask..." -ForegroundColor Cyan
Write-Host "Проверка и установка зависимостей..." -ForegroundColor Cyan
Push-Location $PSScriptRoot

try {
    & $pythonCmd -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Не удалось установить зависимости." -ForegroundColor Red
        Read-Host "Нажмите Enter, чтобы закрыть окно"
        exit 1
    }
}
finally {
    Pop-Location
}

$serverCommand = "cd '$PSScriptRoot'; & '$pythonCmd' host.py --host 127.0.0.1 --port $port"
$serverProcess = Start-Process $shellExe -ArgumentList "-NoExit", "-Command", $serverCommand -PassThru

Start-Sleep -Seconds 3

Write-Host "Запуск публичного туннеля..." -ForegroundColor Cyan
Write-Host "Скопируйте https-ссылку из окна cloudflared и отправьте преподавателю." -ForegroundColor Green
Write-Host ""
Write-Host "Локальный сервер запущен в отдельном окне." -ForegroundColor Yellow
Write-Host "Публичная ссылка появится ниже." -ForegroundColor Yellow
Write-Host "Чтобы остановить доступ, закройте это окно или нажмите Ctrl+C." -ForegroundColor Yellow
Write-Host ""

try {
    & $cloudflaredCmd tunnel --url "http://127.0.0.1:$port"
}
finally {
    if ($serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force
    }
    Read-Host "Туннель остановлен. Нажмите Enter, чтобы закрыть окно"
}
