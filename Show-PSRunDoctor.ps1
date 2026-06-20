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
$form.MinimumSize = [System.Drawing.Size]::new(760, 420)
$form.Size = [System.Drawing.Size]::new(920, 520)

$margin = 18
$fieldLeft = 104
$gap = 12

$title = [System.Windows.Forms.Label]::new()
$title.Text = 'PS Run Doctor'
$title.Font = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$title.Location = [System.Drawing.Point]::new(16, 14)
$title.Size = [System.Drawing.Size]::new(860, 32)

$status = [System.Windows.Forms.Label]::new()
$status.Text = 'Choose a PowerShell script to run in a new PowerShell 7 window.'
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

$browseButton = [System.Windows.Forms.Button]::new()
$browseButton.Text = 'Browse...'
$browseButton.Location = [System.Drawing.Point]::new(728, 87)
$browseButton.Size = [System.Drawing.Size]::new(96, 30)

$runButton = [System.Windows.Forms.Button]::new()
$runButton.Text = 'Run'
$runButton.Location = [System.Drawing.Point]::new(832, 87)
$runButton.Size = [System.Drawing.Size]::new(70, 30)

$suppressUpdateCheck = [System.Windows.Forms.CheckBox]::new()
$suppressUpdateCheck.Text = 'Suppress PowerShell update notice'
$suppressUpdateCheck.Checked = $true
$suppressUpdateCheck.Location = [System.Drawing.Point]::new(104, 128)
$suppressUpdateCheck.Size = [System.Drawing.Size]::new(260, 24)

$report = [System.Windows.Forms.TextBox]::new()
$report.Location = [System.Drawing.Point]::new(18, 170)
$report.Size = [System.Drawing.Size]::new(884, 268)
$report.Multiline = $true
$report.ScrollBars = 'Both'
$report.WordWrap = $false
$report.ReadOnly = $true
$report.Font = [System.Drawing.Font]::new('Consolas', 10)

$copyButton = [System.Windows.Forms.Button]::new()
$copyButton.Text = 'Copy Info'
$copyButton.Location = [System.Drawing.Point]::new(18, 454)
$copyButton.Size = [System.Drawing.Size]::new(100, 30)

$saveButton = [System.Windows.Forms.Button]::new()
$saveButton.Text = 'Save Info'
$saveButton.Location = [System.Drawing.Point]::new(126, 454)
$saveButton.Size = [System.Drawing.Size]::new(100, 30)

$closeButton = [System.Windows.Forms.Button]::new()
$closeButton.Text = 'Close'
$closeButton.Location = [System.Drawing.Point]::new(820, 454)
$closeButton.Size = [System.Drawing.Size]::new(82, 30)

function Update-PSRDLayout {
    $clientWidth = $form.ClientSize.Width
    $clientHeight = $form.ClientSize.Height
    $right = $clientWidth - $margin

    $runButton.Location = [System.Drawing.Point]::new($right - $runButton.Width, 87)
    $browseButton.Location = [System.Drawing.Point]::new($runButton.Left - $gap - $browseButton.Width, 87)

    $scriptPath.Location = [System.Drawing.Point]::new($fieldLeft, 89)
    $scriptPath.Size = [System.Drawing.Size]::new([Math]::Max(220, $browseButton.Left - $gap - $fieldLeft), 26)

    $suppressUpdateCheck.Location = [System.Drawing.Point]::new($fieldLeft, 128)

    $report.Location = [System.Drawing.Point]::new($margin, 170)
    $report.Size = [System.Drawing.Size]::new([Math]::Max(360, $clientWidth - (2 * $margin)), [Math]::Max(160, $clientHeight - 218))

    $bottom = $clientHeight - 48
    $copyButton.Location = [System.Drawing.Point]::new($margin, $bottom)
    $saveButton.Location = [System.Drawing.Point]::new($copyButton.Right + 16, $bottom)
    $closeButton.Location = [System.Drawing.Point]::new($right - $closeButton.Width, $bottom)

    $title.Size = [System.Drawing.Size]::new([Math]::Max(360, $clientWidth - (2 * $margin)), 32)
    $status.Size = [System.Drawing.Size]::new([Math]::Max(360, $clientWidth - (2 * $margin)), 24)
}

$form.Controls.AddRange(@(
    $title,
    $status,
    $scriptLabel,
    $scriptPath,
    $browseButton,
    $runButton,
    $suppressUpdateCheck,
    $report,
    $copyButton,
    $saveButton,
    $closeButton
))

$form.Add_Shown({
    Update-PSRDLayout
})

$form.Add_Resize({
    Update-PSRDLayout
})

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
    $status.Text = 'Opening PowerShell 7 window...'
    $report.Text = ''
    $form.Refresh()

    try {
        $targetPath = (Resolve-Path -LiteralPath $scriptPath.Text -ErrorAction Stop).ProviderPath
        $reportsDirectory = Join-Path $PSScriptRoot 'reports'
        $reportName = 'ps-run-doctor-{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
        $reportPath = Join-Path $reportsDirectory $reportName
        $consoleRunner = Join-Path $PSScriptRoot 'Start-PSRunDoctorConsole.ps1'

        $psi = [Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = [Environment]::ProcessPath
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $false

        if ($suppressUpdateCheck.Checked) {
            $psi.Environment['POWERSHELL_UPDATECHECK'] = 'Off'
        }

        $psi.ArgumentList.Add('-NoExit')
        $psi.ArgumentList.Add('-NoLogo')
        $psi.ArgumentList.Add('-NoProfile')
        $psi.ArgumentList.Add('-ExecutionPolicy')
        $psi.ArgumentList.Add('Bypass')
        $psi.ArgumentList.Add('-File')
        $psi.ArgumentList.Add($consoleRunner)
        $psi.ArgumentList.Add('-ScriptPath')
        $psi.ArgumentList.Add($targetPath)
        $psi.ArgumentList.Add('-ReportPath')
        $psi.ArgumentList.Add($reportPath)
        if ($suppressUpdateCheck.Checked) {
            $psi.ArgumentList.Add('-SuppressPowerShellUpdateCheck')
        }

        [void][Diagnostics.Process]::Start($psi)

        $text = [System.Text.StringBuilder]::new()
        [void]$text.AppendLine('PS Run Doctor GUI')
        [void]$text.AppendLine("Launched: $targetPath")
        [void]$text.AppendLine('Mode: New PowerShell 7 window')
        [void]$text.AppendLine("Report: $reportPath")
        [void]$text.AppendLine('Exit code: written to report after the script exits')
        [void]$text.AppendLine('')
        [void]$text.AppendLine('The script is running in a separate PowerShell 7 window.')
        [void]$text.AppendLine('Answer prompts and review output in that window.')
        [void]$text.AppendLine('The window stays open after the script exits.')
        [void]$text.AppendLine('The report file is written by the PowerShell 7 window.')
        [void]$text.AppendLine('')
        [void]$text.AppendLine('For captured diagnostics, use Invoke-PSRunDoctor.ps1 from PowerShell 7 or Run-PSRunDoctor.cmd with a script path.')

        $report.Text = $text.ToString()
        $status.Text = 'Opened target script in a new PowerShell 7 window.'
    }
    catch {
        $status.Text = 'Could not open the PowerShell 7 window.'
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
        $status.Text = 'Launch info copied to clipboard.'
    }
})

$saveButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($report.Text)) {
        return
    }

    $dialog = [System.Windows.Forms.SaveFileDialog]::new()
    $dialog.Title = 'Save launch info'
    $dialog.Filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*'
    $dialog.FileName = 'ps-run-doctor-launch-info.txt'

    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.IO.File]::WriteAllText($dialog.FileName, $report.Text)
        $status.Text = "Launch info saved: $($dialog.FileName)"
    }
})

$closeButton.Add_Click({
    $form.Close()
})

[void]$form.ShowDialog()
