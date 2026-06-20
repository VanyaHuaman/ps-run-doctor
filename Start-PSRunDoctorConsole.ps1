#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ScriptPath,

    [Parameter(Mandatory)]
    [string]$ReportPath,

    [switch]$SuppressPowerShellUpdateCheck
)

$ErrorActionPreference = 'Stop'

function Write-PSRDLine {
    param(
        [string]$Text = ''
    )

    Write-Host $Text
    Add-Content -LiteralPath $resolvedReport -Value $Text
}

function Write-PSRDSection {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-PSRDLine
    Write-PSRDLine "== $Title =="
}

function Get-PSRDAdminStatus {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PSRDMarkOfTheWeb {
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath
    )

    try {
        $zone = Get-Item -LiteralPath $LiteralPath -Stream Zone.Identifier -ErrorAction Stop
        return $null -ne $zone
    }
    catch {
        return $false
    }
}

$reportDirectory = Split-Path -Parent $ReportPath
if (-not (Test-Path -LiteralPath $reportDirectory -PathType Container)) {
    New-Item -Path $reportDirectory -ItemType Directory -Force | Out-Null
}

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath -ErrorAction Stop).ProviderPath
$resolvedReport = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ReportPath)

if ($SuppressPowerShellUpdateCheck) {
    $env:POWERSHELL_UPDATECHECK = 'Off'
}

$targetExitCode = $null

try {
    Set-Content -LiteralPath $resolvedReport -Value 'PS Run Doctor interactive console run'
    Write-Host 'PS Run Doctor interactive console run'
    Write-PSRDLine "Started:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
    Write-PSRDLine "Script:     $resolvedScript"
    Write-PSRDLine "Report:     $resolvedReport"

    Write-PSRDSection 'PowerShell'
    Write-PSRDLine "Executable: $([Environment]::ProcessPath)"
    Write-PSRDLine "Version:    $($PSVersionTable.PSVersion)"
    Write-PSRDLine "Edition:    $($PSVersionTable.PSEdition)"
    Write-PSRDLine "OS:         $($PSVersionTable.OS)"
    Write-PSRDLine "Admin:      $(Get-PSRDAdminStatus)"

    Write-PSRDSection 'Execution Policy'
    $executionPolicyText = Get-ExecutionPolicy -List | Format-Table -AutoSize | Out-String
    Write-Host $executionPolicyText
    Add-Content -LiteralPath $resolvedReport -Value $executionPolicyText

    Write-PSRDSection 'Target Script'
    Write-PSRDLine "Resolved:   $resolvedScript"
    Write-PSRDLine "Downloaded file marker: $(Test-PSRDMarkOfTheWeb -LiteralPath $resolvedScript)"

    Write-PSRDSection 'Run Target'
    Write-PSRDLine 'The target script is running below. Answer prompts in this window.'
    Write-PSRDLine

    $arguments = @(
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $resolvedScript
    )

    & ([Environment]::ProcessPath) @arguments 2>&1 | Tee-Object -FilePath $resolvedReport -Append
    $targetExitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }

    Write-PSRDSection 'Result'
    Write-PSRDLine "Exit code: $targetExitCode"
    if ($targetExitCode -eq 0) {
        Write-PSRDLine 'Target script completed successfully.'
    }
    else {
        Write-PSRDLine 'Target script failed or returned a non-zero exit code.'
    }
}
catch {
    $targetExitCode = 1
    Write-PSRDSection 'Launcher Error'
    $errorText = $_ | Out-String
    Write-Error $errorText
    Add-Content -LiteralPath $resolvedReport -Value $errorText
}
finally {
    Write-Host ''
    Write-Host "PS Run Doctor report saved to: $resolvedReport" -ForegroundColor Green
    Write-Host 'This PowerShell window was left open so you can review the output.' -ForegroundColor Yellow
    $global:LASTEXITCODE = $targetExitCode
}
