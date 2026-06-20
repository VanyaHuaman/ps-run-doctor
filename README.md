# PS Run Doctor

PS Run Doctor is a Windows helper for running `.ps1` scripts with PowerShell 7 and collecting troubleshooting information.

It is built for cases where a user sees confusing PowerShell startup noise, execution policy issues, missing-file errors, script prompts, or script failures and needs a clearer report of what happened.

## Requirements

- Windows 10 or later
- PowerShell 7 or later (`pwsh.exe`)
- A `.ps1` script to run

Check whether PowerShell 7 is installed:

```cmd
pwsh --version
```

If PowerShell 7 is missing, install it with:

```cmd
winget install --id Microsoft.PowerShell --source winget
```

After installing PowerShell 7, close and reopen Command Prompt or PowerShell before running PS Run Doctor again.

## Setup

1. Download or clone this repository.

   ```cmd
   gh repo clone VanyaHuaman/ps-run-doctor
   ```

2. Open Command Prompt.

3. Change into the project folder.

   ```cmd
   cd C:\Users\vanya\ps-run-doctor
   ```

4. Start the GUI.

   ```cmd
   Run-PSRunDoctor.cmd
   ```

The `.cmd` launcher is intentional. It lets a user start the tool without first running a PowerShell script manually.

## Use The GUI

Use the GUI when the script may ask questions, show menus, pause, or need live input from the user.

1. Run:

   ```cmd
   Run-PSRunDoctor.cmd
   ```

2. Click `Browse...`.

3. Select the `.ps1` script you want to run.

4. Leave `Suppress PowerShell update notice` checked unless you specifically want to see PowerShell startup update messages.

5. Click `Run`.

6. PS Run Doctor opens a new PowerShell 7 window.

7. Answer prompts and review output in that PowerShell 7 window.

8. When the script finishes, leave the window open long enough to review any errors.

9. Find the report in:

   ```text
   reports\
   ```

The report filename is timestamped, for example:

```text
reports\ps-run-doctor-20260619-193806.txt
```

## What The GUI Report Includes

Each GUI run writes a report with:

- PowerShell executable path
- PowerShell version and edition
- operating system
- administrator status
- execution policy list
- target script path
- downloaded-file marker check
- script output
- script error output
- final exit code
- success or failure summary

## Use The CLI

Use the CLI when you want a fully captured diagnostic run in the current terminal.

Run a script:

```cmd
Run-PSRunDoctor.cmd path\to\YourScript.ps1
```

Or run directly from PowerShell 7:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Invoke-PSRunDoctor.ps1 -ScriptPath .\YourScript.ps1 -SuppressPowerShellUpdateCheck
```

Pass script arguments:

```powershell
.\Invoke-PSRunDoctor.ps1 -ScriptPath .\YourScript.ps1 -ScriptArguments @('-Name', 'Test')
```

Pass preset answers to a script that uses `Read-Host`:

```powershell
.\Invoke-PSRunDoctor.ps1 -ScriptPath .\YourScript.ps1 -InputText "06192026`nY" -SuppressPowerShellUpdateCheck
```

## Test Scripts

The repo includes test scripts for verifying the tool:

```cmd
Run-PSRunDoctor.cmd examples\hello-success.ps1
Run-PSRunDoctor.cmd examples\hello-failure.ps1
Run-PSRunDoctor.cmd examples\read-host-date.ps1
Run-PSRunDoctor.cmd examples\read-host-multiple.ps1
```

There is also a generic interactive test script:

```text
scripts\Test-PSRunDoctorInteractive.ps1
```

To test it through the GUI, browse to that file and click `Run`.

## Update Notification Note

PowerShell 7 can print an update notification at startup. That message does not prove the script failed.

PS Run Doctor can suppress that startup notice for child PowerShell processes by setting:

```powershell
$env:POWERSHELL_UPDATECHECK = 'Off'
```

The GUI exposes this as `Suppress PowerShell update notice`.

## Limits

PS Run Doctor uses process-scoped execution policy bypass for the PowerShell process it starts. It does not change the machine's permanent execution policy.

It cannot bypass:

- organization-managed execution policy
- AppLocker or Windows Defender Application Control
- antivirus blocks
- missing PowerShell 7
- missing script dependencies
- broken paths inside the target script
- scripts that require applications not installed on the machine, such as Excel automation scripts when Excel is missing

If PS Run Doctor cannot start PowerShell 7, that is useful evidence: the problem is earlier than the target script.
