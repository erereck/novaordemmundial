$ErrorActionPreference = 'SilentlyContinue'

function Normalize-Name([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    return (($Text.ToLowerInvariant()) -replace '[^a-z0-9]', '')
}

$debugDir = Join-Path $env:LOCALAPPDATA 'NovaOrdemMundial'
$debugPath = Join-Path $debugDir 'typingland-debug.txt'
New-Item -ItemType Directory -Force -Path $debugDir | Out-Null

$debug = New-Object System.Collections.Generic.List[string]
$debug.Add("Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$debug.Add("Windows: $([Environment]::OSVersion.VersionString)")
$debug.Add('')

function Launch-Aumid([string]$Aumid) {
    if ([string]::IsNullOrWhiteSpace($Aumid)) { return $false }

    # Primeiro tenta abrir o item real do shell AppsFolder.
    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace('shell:AppsFolder')
        if ($null -ne $folder) {
            $item = $folder.ParseName($Aumid)
            if ($null -ne $item) {
                $item.InvokeVerb('open')
                Start-Sleep -Milliseconds 300
                return $true
            }
        }
    } catch {
        $debug.Add("COM launch error: $($_.Exception.Message)")
    }

    # Fallback oficial/pratico do Explorer para AUMID.
    try {
        Start-Process -FilePath 'explorer.exe' -ArgumentList ("shell:AppsFolder\" + $Aumid)
        Start-Sleep -Milliseconds 300
        return $true
    } catch {
        $debug.Add("Explorer launch error: $($_.Exception.Message)")
    }

    return $false
}

# 1) Tenta pelo menu Iniciar, aceitando Typing Land / TypingLand / variacoes.
$debug.Add('=== Get-StartApps ===')
$startApps = @(Get-StartApps)
$candidates = @()
foreach ($app in $startApps) {
    $norm = Normalize-Name $app.Name
    if ($norm -like '*typing*' -or $norm -like '*land*') {
        $debug.Add("$($app.Name) | $($app.AppID)")
    }

    if ($norm -eq 'typingland' -or ($norm.Contains('typing') -and $norm.Contains('land'))) {
        $candidates += $app.AppID
    }
}

foreach ($aumid in $candidates) {
    if (Launch-Aumid $aumid) {
        Remove-Item -LiteralPath $debugPath -Force -ErrorAction SilentlyContinue
        exit 0
    }
}

# 2) Procura pelo pacote MSIX/UWP instalado e monta o AUMID pelo manifesto.
$debug.Add('')
$debug.Add('=== Get-AppxPackage ===')
foreach ($pkg in @(Get-AppxPackage)) {
    $text = Normalize-Name ($pkg.Name + ' ' + $pkg.PackageFamilyName + ' ' + $pkg.PackageFullName)
    if (-not ($text.Contains('typing') -and $text.Contains('land'))) { continue }

    $debug.Add("PACKAGE: $($pkg.Name) | $($pkg.PackageFamilyName)")

    try {
        $manifest = Get-AppxPackageManifest $pkg
        foreach ($application in @($manifest.Package.Applications.Application)) {
            $id = [string]$application.Id
            $exe = [string]$application.Executable
            $entry = [string]$application.EntryPoint
            $debug.Add("  APP: Id=$id | Exe=$exe | Entry=$entry")

            if ($id) {
                $aumid = "$($pkg.PackageFamilyName)!$id"
                if (Launch-Aumid $aumid) {
                    Remove-Item -LiteralPath $debugPath -Force -ErrorAction SilentlyContinue
                    exit 0
                }
            }
        }
    } catch {
        $debug.Add("  MANIFEST ERROR: $($_.Exception.Message)")
    }
}

# 3) Ultimo fallback: varre diretamente os itens do AppsFolder por nome.
$debug.Add('')
$debug.Add('=== shell:AppsFolder ===')
try {
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace('shell:AppsFolder')
    if ($null -ne $folder) {
        foreach ($item in @($folder.Items())) {
            $name = [string]$item.Name
            $norm = Normalize-Name $name
            if ($norm -like '*typing*' -or $norm -like '*land*') {
                $debug.Add("ITEM: $name | Path=$($item.Path)")
            }

            if ($norm -eq 'typingland' -or ($norm.Contains('typing') -and $norm.Contains('land'))) {
                try {
                    $item.InvokeVerb('open')
                    Remove-Item -LiteralPath $debugPath -Force -ErrorAction SilentlyContinue
                    exit 0
                } catch {
                    $debug.Add("  ITEM OPEN ERROR: $($_.Exception.Message)")
                }
            }
        }
    }
} catch {
    $debug.Add("AppsFolder error: $($_.Exception.Message)")
}

$debug.Add('')
$debug.Add('FALHA: Typing Land nao foi localizado/aberto pelo Windows.')
Set-Content -LiteralPath $debugPath -Value $debug -Encoding UTF8
exit 2
