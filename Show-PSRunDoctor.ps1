#Requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if (-not $IsWindows) {
    throw 'PS Run Doctor GUI requires Windows.'
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = [System.Windows.Forms.Form]::new()
$form.Text = 'PS Run Doctor'
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = [System.Drawing.Size]::new(780, 560)
$form.Size = [System.Drawing.Size]::new(920, 660)

$title = [System.Windows.Forms.Label]::new()
$title.Text = 'PS Run Doctor'
$title.Font = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$title.Location = [System.Drawing.Point]::new(16, 14)
$title.Size = [System.Drawing.Size]::new(860, 32)

$status = [System.Windows.Forms.Label]::new()
$status.Text = 'Choose a PowerShell script to diagnose.'
$status.Font = [System.Drawing.Font]::new('Segoe UI', 10)
$status.Location = [System.Drawing.Point]::new(18, 52)
$status.Size = [System.Drawing.Size]::new(860, 24)

$scriptLabel = [System.Windows.Forms.Label]::new()
$scriptLabel.Text = 'Script'
$scriptLabel.Location = [System.Drawing.Point]::new(18, 92)
$scriptLabel.Size = [System.Drawing.Size]::new(80, 24)

$scriptPath = [System.Windows.Forms.TextBox]::new()
$scriptPath.Location = [System.Drawing.Point]::new(104, 89)
$scriptPath.Size = [System.Drawing.Size]::new(610, 26)
$scriptPath.Anchor = 'Top,Left,Right'

$browseButton = [System.Windows.Forms.Button]::new()
$browseButton.Text = 'Browse...'
$browseButton.Location = [System.Drawing.Point]::new(728, 87)
$browseButton.Size = [System.Drawing.Size]::new(88, 30)
$browseButton.Anchor = 'Top,Right'

$runButton = [System.Windows.Forms.Button]::new()
$runButton.Text = 'Run Check'
$runButton.Location = [System.Drawing.Point]::new(824, 87)
$runButton.Size = [System.Drawing.Size]::new(82, 30)
$runButton.Anchor = 'Top,Right'

$report = [System.Windows.Forms.TextBox]::new()
$report.Location = [System.Drawing.Point]::new(18, 132)
$report.Size = [System.Drawing.Size]::new(888, 430)
$report.Anchor = 'Top,Bottom,Left,Right'
$report.Multiline = $true
$report.ScrollBars = 'Both'
$report.WordWrap = $false
$report.ReadOnly = $true
$report.Font = [System.Drawing.Font]::new('Consolas', 10)

$copyButton = [System.Windows.Forms.Button]::new()
$copyButton.Text = 'Copy Report'
$copyButton.Location = [System.Drawing.Point]::new(18, 578)
$copyButton.Size = [System.Drawing.Size]::new(100, 30)
$copyButton.Anchor = 'Bottom,Left'

$saveButton = [System.Windows.Forms.Button]::new()
$saveButton.Text = 'Save Report'
$saveButton.Location = [System.Drawing.Point]::new(126, 578)
$saveButton.Size = [System.Drawing.Size]::new(100, 30)
$saveButton.Anchor = 'Bottom,Left'

$closeButton = [System.Windows.Forms.Button]::new()
$closeButton.Text = 'Close'
$closeButton.Location = [System.Drawing.Point]::new(824, 578)
$closeButton.Size = [System.Drawing.Size]::new(82, 30)
$closeButton.Anchor = 'Bottom,Right'

$form.Controls.AddRange(@(
    $title,
    $status,
    $scriptLabel,
    $scriptPath,
    $browseButton,
    $runButton,
    $report,
    $copyButton,
    $saveButton,
    $closeButton
))

$browseButton.Add_Click({
    $dialog = [System.Windows.Forms.OpenFileDialog]::new()
    $dialog.Title = 'Choose a PowerShell script'
    $dialog.Filter = 'PowerShell scripts (*.ps1)|*.ps1|All files (*.*)|*.*'
    $dialog.CheckFileExists = $true

    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $scriptPath.Text = $dialog.FileName
    }
})

$runButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($scriptPath.Text)) {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            'Choose a PowerShell script first.',
            'PS Run Doctor',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $runButton.Enabled = $false
    $browseButton.Enabled = $false
    $status.Text = 'Running diagnostic check...'
    $report.Text = ''
    $form.Refresh()

    try {
        $runner = Join-Path $PSScriptRoot 'Invoke-PSRunDoctor.ps1'

        $psi = [Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = [Environment]::ProcessPath
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.Environment['POWERSHELL_UPDATECHECK'] = 'Off'
        $psi.ArgumentList.Add('-NoLogo')
        $psi.ArgumentList.Add('-NoProfile')
        $psi.ArgumentList.Add('-ExecutionPolicy')
        $psi.ArgumentList.Add('Bypass')
        $psi.ArgumentList.Add('-File')
        $psi.ArgumentList.Add($runner)
        $psi.ArgumentList.Add('-ScriptPath')
        $psi.ArgumentList.Add($scriptPath.Text)
        $psi.ArgumentList.Add('-SuppressPowerShellUpdateCheck')

        $process = [Diagnostics.Process]::Start($psi)
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        $text = [System.Text.StringBuilder]::new()
        [void]$text.AppendLine("PS Run Doctor GUI")
        [void]$text.AppendLine("Checked: $($scriptPath.Text)")
        [void]$text.AppendLine("Exit code: $($process.ExitCode)")
        [void]$text.AppendLine('')

        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            [void]$text.AppendLine($stdout.TrimEnd())
        }

        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            [void]$text.AppendLine('')
            [void]$text.AppendLine('== Launcher Errors ==')
            [void]$text.AppendLine($stderr.TrimEnd())
        }

        $report.Text = $text.ToString()

        if ($process.ExitCode -eq 0) {
            $status.Text = 'Target script completed successfully.'
        }
        else {
            $status.Text = 'Target script failed or returned a non-zero exit code.'
        }
    }
    catch {
        $status.Text = 'Could not run the diagnostic check.'
        $report.Text = $_ | Out-String
    }
    finally {
        $runButton.Enabled = $true
        $browseButton.Enabled = $true
    }
})

$copyButton.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($report.Text)) {
        [System.Windows.Forms.Clipboard]::SetText($report.Text)
        $status.Text = 'Report copied to clipboard.'
    }
})

$saveButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($report.Text)) {
        return
    }

    $dialog = [System.Windows.Forms.SaveFileDialog]::new()
    $dialog.Title = 'Save diagnostic report'
    $dialog.Filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*'
    $dialog.FileName = 'ps-run-doctor-report.txt'

    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.IO.File]::WriteAllText($dialog.FileName, $report.Text)
        $status.Text = "Report saved: $($dialog.FileName)"
    }
})

$closeButton.Add_Click({
    $form.Close()
})

[void]$form.ShowDialog()
