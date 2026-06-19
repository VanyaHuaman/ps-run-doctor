# PS Run Doctor

PS Run Doctor is a PowerShell 7 helper for diagnosing what happened when someone tried to run a `.ps1` script on Windows.

It is built for a common confusing case: PowerShell prints an update notification such as:

```text
A new PowerShell variant is available! Please update to the latest version of PowerShell for new features and improvements!
```

That message can appear at PowerShell startup and does not prove the script failed. PS Run Doctor records the environment, runs a target script, captures output, and reports whether the target script started, exited successfully, or failed.

## Requirements

- Windows 10 or later
- PowerShell 7 or later (`pwsh`)

## Quick Start

If normal PowerShell script execution is the problem, start with the Windows command launcher. Double-click it to open the GUI:

```cmd
Run-PSRunDoctor.cmd
```

Or pass a script path to run console mode:

```cmd
Run-PSRunDoctor.cmd path\to\YourScript.ps1
```

The launcher runs through `cmd.exe`, then starts PowerShell 7 with a process-scoped execution policy bypass.

From PowerShell 7, you can also run:

```powershell
.\Invoke-PSRunDoctor.ps1 -ScriptPath .\YourScript.ps1
```

If script execution is blocked, start it with a process-scoped bypass:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Invoke-PSRunDoctor.ps1 -ScriptPath .\YourScript.ps1
```

To pass arguments to the target script:

```powershell
.\Invoke-PSRunDoctor.ps1 -ScriptPath .\YourScript.ps1 -ScriptArguments @('-Name', 'Test')
```

To verify PS Run Doctor itself:

```cmd
Run-PSRunDoctor.cmd examples\hello-success.ps1
Run-PSRunDoctor.cmd examples\hello-failure.ps1
```

## What It Checks

- PowerShell edition and version
- Operating system
- Whether the session is running as administrator
- Execution policy by scope
- Whether the target script exists
- Whether the target script appears to be blocked by Mark-of-the-Web
- Whether the target script starts and what exit code it returns
- Standard output and error from the target script

## GUI

The GUI is launched by `Run-PSRunDoctor.cmd` when no script path is provided. It lets the user choose a `.ps1` file, run the check, copy the report, or save the report.

The GUI is intentionally launched from the `.cmd` file so users do not have to run a PowerShell script manually first.

## Update Notification Note

PowerShell 7 has a built-in update notification feature. Microsoft documents that it runs at startup and can be controlled with the `POWERSHELL_UPDATECHECK` environment variable.

For one session, you can suppress that notice before starting a child PowerShell process:

```powershell
$env:POWERSHELL_UPDATECHECK = 'Off'
```

PS Run Doctor does not hide target script errors. It separates startup noise from the result of the script you meant to run.

## Bootstrap Limits

The `.cmd` launcher handles common script execution policy problems because it starts PowerShell with `-ExecutionPolicy Bypass` for that process only. It cannot bypass organization-managed policy, AppLocker, antivirus blocks, missing PowerShell 7, or a damaged Windows install.

If the launcher cannot start PowerShell 7, that is useful evidence: the problem is earlier than the target script.
