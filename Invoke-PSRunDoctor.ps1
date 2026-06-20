#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ScriptPath,

    [string[]]$ScriptArguments = @(),

    [string]$InputText,

    [switch]$SuppressPowerShellUpdateCheck
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot 'src/PSRunDoctor/PSRunDoctor.psd1'
Import-Module $modulePath -Force

$exitCode = Invoke-PSRunDoctor `
    -ScriptPath $ScriptPath `
    -ScriptArguments $ScriptArguments `
    -InputText $InputText `
    -SuppressPowerShellUpdateCheck:$SuppressPowerShellUpdateCheck

exit $exitCode
