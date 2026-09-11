param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Normalize-Name([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    return (($Text.ToLowerInvariant()) -replace '[^a-z0-9]', '')
}

$needle = Normalize-Name $Name
$debugDir = Join-Path $env:LOCALAPPDATA 'NovaOrdemMundial'
$debugPath = Join-Path $debugDir 'store-app-debug.txt'
New-Item -ItemType Directory -Force -Path $debugDir | Out-Null

$debug = New-Object System.Collections.Generic.List[string]
$debug.Add("Busca: $Name")
$debug.Add("Normalizado: $needle")
$debug.Add('')
$debug.Add('=== Get-StartApps ===')

# 1) Melhor caminho: AppUserModelID ja registrado no menu Iniciar.
$startApps = @(Get-StartApps)
foreach ($app in $startApps) {
    $norm = Normalize-Name $app.Name
    if ($norm -like '*typing*' -or $norm -like '*land*') {
        $debug.Add("$($app.Name) | $($app.AppID)")
    }

    if ($norm -eq $needle -or $norm.Contains($needle) -or $needle.Contains($norm)) {
        if ($app.AppID) {
            Remove-Item -LiteralPath $debugPath -Force -ErrorAction SilentlyContinue
            [Console]::Out.Write($app.AppID)
            exit 0
        }
    }
}

$debug.Add('')
$debug.Add('=== Get-AppxPackage ===')

# 2) Fallback MSIX/UWP: procura pacotes cujo nome/familia lembre Typing Land,
# abre o manifesto e monta PackageFamilyName!ApplicationId.
$packages = @(Get-AppxPackage)
foreach ($pkg in $packages) {
    $packageText = Normalize-Name ($pkg.Name + ' ' + $pkg.PackageFamilyName + ' ' + $pkg.PackageFullName)
    $looksRelevant = $packageText.Contains($needle) -or ($packageText.Contains('typing') -and $packageText.Contains('land'))

    if (-not $looksRelevant) { continue }

    $debug.Add("PACKAGE: $($pkg.Name) | $($pkg.PackageFamilyName)")

    try {
        $manifest = Get-AppxPackageManifest $pkg
        $applications = @($manifest.Package.Applications.Application)

        foreach ($application in $applications) {
            $appId = [string]$application.Id
            $exe = [string]$application.Executable
            $entry = [string]$application.EntryPoint
            $debug.Add("  APP: Id=$appId | Exe=$exe | Entry=$entry")

            if ($appId) {
                $aumid = "$($pkg.PackageFamilyName)!$appId"
                Remove-Item -LiteralPath $debugPath -Force -ErrorAction SilentlyContinue
                [Console]::Out.Write($aumid)
                exit 0
            }
        }
    } catch {
        $debug.Add("  MANIFEST ERROR: $($_.Exception.Message)")
    }
}

$debug.Add('')
$debug.Add('Nenhum AppUserModelID compativel foi encontrado.')
Set-Content -LiteralPath $debugPath -Value $debug -Encoding UTF8
exit 2
