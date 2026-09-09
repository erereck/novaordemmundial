param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Get-StartApps devolve o AppUserModelID real registrado pelo Windows,
# que e muito mais confiavel do que tentar descobrir o .exe de um app MSIX.
$app = Get-StartApps |
    Where-Object { $_.Name -like "*$Name*" } |
    Select-Object -First 1

if ($null -ne $app -and $app.AppID) {
    [Console]::Out.Write($app.AppID)
    exit 0
}

exit 2
