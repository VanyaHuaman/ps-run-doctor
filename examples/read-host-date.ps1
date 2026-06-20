#Requires -Version 7.0

$processingDate = Read-Host 'Please enter the processing date in mmddyyyy format'

if ($processingDate -notmatch '^(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{4}$') {
    Write-Error 'Invalid date format. Please use mmddyyyy.'
    exit 1
}

Write-Host "Received processing date: $processingDate"
exit 0
