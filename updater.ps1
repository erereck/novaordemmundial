param(
    [Parameter(Mandatory=$true)]
    [string]$Root,

    [int]$PidToWait = 0
)

$ErrorActionPreference = 'Stop'

function Write-UpdateError([string]$Message) {
    try {
        $path = Join-Path $Root 'update-error.txt'
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Set-Content -LiteralPath $path -Value "[$stamp] $Message" -Encoding UTF8
    } catch {
    }
}

$tempRoot = Join-Path $env:TEMP ("novaordemmundial-update-" + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot 'main.zip'
$extractPath = Join-Path $tempRoot 'extract'

try {
    if ($PidToWait -gt 0) {
        try {
            Wait-Process -Id $PidToWait -ErrorAction SilentlyContinue
        } catch {
        }
    }

    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null

    Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/erereck/novaordemmundial/archive/refs/heads/main.zip' -OutFile $zipPath

    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $source = Join-Path $extractPath 'novaordemmundial-main'
    if (-not (Test-Path -LiteralPath $source)) {
        throw 'Pasta extraida do update nao encontrada.'
    }

    # Copia a versao nova sem apagar arquivos locais e sem sobrescrever
    # configuracoes especificas de cada computador.
    & robocopy $source $Root /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP /XF settings.ini /XD cache .git | Out-Null
    $rc = $LASTEXITCODE
    if ($rc -gt 7) {
        throw "Robocopy falhou com codigo $rc"
    }

    $errorFile = Join-Path $Root 'update-error.txt'
    if (Test-Path -LiteralPath $errorFile) {
        Remove-Item -LiteralPath $errorFile -Force -ErrorAction SilentlyContinue
    }

    $launcher = Join-Path $Root 'ABRIR_MODO_ALUNO.bat'
    if (Test-Path -LiteralPath $launcher) {
        Start-Process -FilePath $launcher -WorkingDirectory $Root
    } else {
        throw 'ABRIR_MODO_ALUNO.bat nao encontrado depois do update.'
    }
} catch {
    Write-UpdateError $_.Exception.Message
} finally {
    try {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
    }
}
