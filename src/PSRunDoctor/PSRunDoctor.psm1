Set-StrictMode -Version Latest

function Get-PSRDAdminStatus {
    if (-not $IsWindows) {
        return $false
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PSRDExecutionPolicyReport {
    if (-not $IsWindows) {
        return @()
    }

    $scopes = 'MachinePolicy', 'UserPolicy', 'Process', 'CurrentUser', 'LocalMachine'

    foreach ($scope in $scopes) {
        [pscustomobject]@{
            Scope = $scope
            Policy = Get-ExecutionPolicy -Scope $scope
        }
    }
}

function Test-PSRDMarkOfTheWeb {
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath
    )

    if (-not $IsWindows) {
        return $false
    }

    try {
        $zone = Get-Item -LiteralPath $LiteralPath -Stream Zone.Identifier -ErrorAction Stop
        return $null -ne $zone
    }
    catch {
        return $false
    }
}

function Write-PSRDSection {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ''
    Write-Host "== $Title =="
}

function Invoke-PSRunDoctor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [string[]]$ScriptArguments = @(),

        [switch]$SuppressPowerShellUpdateCheck
    )

    $resolvedScript = $null
    $scriptExists = $false

    try {
        $resolvedScript = (Resolve-Path -LiteralPath $ScriptPath -ErrorAction Stop).ProviderPath
        $scriptExists = $true
    }
    catch {
        $resolvedScript = $ScriptPath
    }

    Write-PSRDSection 'PowerShell'
    Write-Host "Executable: $([Environment]::ProcessPath)"
    Write-Host "Version:    $($PSVersionTable.PSVersion)"
    Write-Host "Edition:    $($PSVersionTable.PSEdition)"
    Write-Host "OS:         $($PSVersionTable.OS)"
    Write-Host "Admin:      $(Get-PSRDAdminStatus)"

    Write-PSRDSection 'Execution Policy'
    $policies = Get-PSRDExecutionPolicyReport
    if ($policies.Count -eq 0) {
        Write-Host 'Execution policy is only enforced on Windows.'
    }
    else {
        $policies | Format-Table -AutoSize | Out-Host
    }

    Write-PSRDSection 'Target Script'
    Write-Host "Requested:  $ScriptPath"
    Write-Host "Resolved:   $resolvedScript"
    Write-Host "Exists:     $scriptExists"

    if (-not $scriptExists) {
        Write-Error "Target script was not found: $ScriptPath"
        return 1
    }

    $blocked = Test-PSRDMarkOfTheWeb -LiteralPath $resolvedScript
    Write-Host "Downloaded file marker: $blocked"

    if ($blocked) {
        Write-Host "Suggestion: run Unblock-File -LiteralPath '$resolvedScript' if you trust this script."
    }

    Write-PSRDSection 'Run Target'

    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = [Environment]::ProcessPath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    if ($SuppressPowerShellUpdateCheck) {
        $psi.Environment['POWERSHELL_UPDATECHECK'] = 'Off'
    }

    $psi.ArgumentList.Add('-NoLogo')
    $psi.ArgumentList.Add('-NoProfile')
    $psi.ArgumentList.Add('-ExecutionPolicy')
    $psi.ArgumentList.Add('Bypass')
    $psi.ArgumentList.Add('-File')
    $psi.ArgumentList.Add($resolvedScript)

    foreach ($argument in $ScriptArguments) {
        $psi.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    Write-Host "Started:   True"
    Write-Host "Exit code: $($process.ExitCode)"

    Write-PSRDSection 'Target Output'
    if ([string]::IsNullOrWhiteSpace($stdout)) {
        Write-Host '<no stdout>'
    }
    else {
        Write-Host $stdout.TrimEnd()
    }

    Write-PSRDSection 'Target Errors'
    if ([string]::IsNullOrWhiteSpace($stderr)) {
        Write-Host '<no stderr>'
    }
    else {
        Write-Host $stderr.TrimEnd()
    }

    Write-PSRDSection 'Result'
    if ($process.ExitCode -eq 0) {
        Write-Host 'Target script completed successfully.'
    }
    else {
        Write-Host 'Target script failed or returned a non-zero exit code.'
    }

    return $process.ExitCode
}

Export-ModuleMember -Function Invoke-PSRunDoctor
