# AI Handoff

## Project

PS Run Doctor is a Windows helper for running `.ps1` scripts with PowerShell 7 and collecting troubleshooting information.

The main user goal is a universal tool, not a tool tied to one customer script. The GUI should let a non-technical user pick any PowerShell script, run it in a real PowerShell 7 window, answer prompts there, and still produce a report with useful troubleshooting details.

## Current Behavior

- `Run-PSRunDoctor.cmd` with no arguments opens the GUI.
- `Run-PSRunDoctor.cmd path\to\script.ps1` runs the CLI diagnostic path.
- GUI runs target scripts in a new PowerShell 7 window through `Start-PSRunDoctorConsole.ps1`.
- GUI-created reports are written under `reports\`.
- `reports\` is ignored by git.
- GUI shows the PowerShell 7 version/path it is using.
- GUI has:
  - script path textbox
  - `Browse...`
  - `Run`
  - `Suppress PowerShell update notice`
  - `Run PowerShell 7 as administrator`
  - launch info box with copy/save buttons
- Admin mode uses `ProcessStartInfo.Verb = 'runas'`, so Windows UAC prompts the user.

## Important Files

- `Run-PSRunDoctor.cmd`: bootstrap launcher. Verifies `pwsh.exe` exists, opens GUI or CLI mode.
- `Show-PSRunDoctor.ps1`: WinForms GUI. Launches scripts in a new PowerShell 7 window.
- `Start-PSRunDoctorConsole.ps1`: interactive console wrapper. Writes report sections, runs target script, tees output/error to report, records exit code.
- `Invoke-PSRunDoctor.ps1`: CLI entry point for captured diagnostics.
- `src/PSRunDoctor/PSRunDoctor.psm1`: module implementation for CLI diagnostics.
- `README.md`: user setup and usage instructions.
- `examples\`: simple CLI test scripts.
- `scripts\Test-PSRunDoctorInteractive.ps1`: generic interactive GUI test script.

## Design Decisions

- The GUI is intentionally interactive-first. It does not try to capture stdin in the GUI because real scripts may ask questions, show menus, pause, or require credentials.
- The CLI remains the captured diagnostic path for non-interactive scripts or scripts with preset `Read-Host` answers.
- The repo must not include the user's father-in-law-specific rent transaction script. A fixed copy was created separately on the user's Desktop when requested, but it should not be committed here.
- Do not change `.ps1` file associations or registry defaults. The README explains safer ways to make PowerShell 7 the practical default.
- Use PowerShell 7 (`pwsh.exe`) everywhere user scripts are launched.

## Verification Commands

Parse check:

```powershell
pwsh -NoLogo -NoProfile -Command "& { `$ErrorActionPreference = 'Stop'; `$files = Get-ChildItem -Recurse -Include *.ps1,*.psm1,*.psd1; foreach (`$file in `$files) { `$tokens = `$null; `$errors = `$null; [System.Management.Automation.Language.Parser]::ParseFile(`$file.FullName, [ref]`$tokens, [ref]`$errors) > `$null; if (`$errors.Count -gt 0) { Write-Error \"Parse failed: `$(`$file.FullName) `$(`$errors[0].Message)\" } }; 'parse ok' }"
```

CLI success smoke test:

```cmd
Run-PSRunDoctor.cmd examples\hello-success.ps1
```

Interactive wrapper smoke test:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Start-PSRunDoctorConsole.ps1 -ScriptPath .\examples\hello-success.ps1 -ReportPath .\reports\test-hello-success.txt -SuppressPowerShellUpdateCheck
```

GUI test:

```cmd
Run-PSRunDoctor.cmd
```

Then browse to:

```text
scripts\Test-PSRunDoctorInteractive.ps1
```

Expected result: a new PowerShell 7 window opens, asks for input, stays open after completion, and writes a report under `reports\`.

## Known Notes

- Git may warn: `unable to access 'C:\Users\vanya/.config/git/ignore': Permission denied`. This has not blocked commits or pushes.
- The admin GUI path cannot set `ProcessStartInfo.Environment` because elevation requires `UseShellExecute = $true`. The wrapper still receives `-SuppressPowerShellUpdateCheck` and sets `POWERSHELL_UPDATECHECK` after the elevated window starts.
- `Start-PSRunDoctorConsole.ps1` uses `Tee-Object` to show target output live and append it to the report.
- Fully interactive console apps that write directly to the console host may not be perfectly captured, but normal PowerShell stdout/stderr is captured.

## Latest Uncommitted Intent At Handoff Creation

Before this handoff file, the pending changes were:

- README updates for checking PowerShell 7, admin mode, and practical default guidance.
- GUI updates to show PowerShell 7 version/path and add admin launch checkbox.

Those should be committed with this handoff.
