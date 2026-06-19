@{
    RootModule = 'PSRunDoctor.psm1'
    ModuleVersion = '0.1.0'
    GUID = '602DC5BA-E94B-422B-9C12-1236B10A4D06'
    Author = 'PS Run Doctor'
    CompanyName = 'Unknown'
    Copyright = '(c) 2026. All rights reserved.'
    Description = 'Diagnoses PowerShell 7 script launch problems on Windows.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Invoke-PSRunDoctor')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Diagnostics', 'Windows', 'Scripts')
            ProjectUri = ''
        }
    }
}
