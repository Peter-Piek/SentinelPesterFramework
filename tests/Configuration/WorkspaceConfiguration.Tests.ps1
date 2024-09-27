#region Install required modules
if ( -not (Get-Module -ListAvailable Az.Accounts) ) {
    Install-Module Az.Accounts -Force -AllowClobber
}

if ( -not (Get-Module -ListAvailable ImportExcel) ) {
    Install-Module ImportExcel -Force -AllowClobber
}
#endregion

$workspaceName = "MRP-EU-Log-Analytics-1"
$resourceGroup = "north-eu-rg1"
$subscriptionId = "c5630f6e-58ef-4aa1-92f3-f7a2efa6af8e"

$configRunContainer = New-PesterContainer -Path "*.Tests.ps1" -Data @{
    workspaceName  = $workspaceName
    resourceGroup  = $resourceGroup
    subscriptionId = $subscriptionId
}

Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

$config = New-PesterConfiguration -Hashtable @{
    Filter     = @{
        Tag = "Configuration", "EntraID", "EntraIDProtection", "AzureActivity", "DCAS", "M365", "DataConnectorsReqs", "SecuirtyEvents", "AMADNS", "WinFirewall"
    }
    TestResult = @{ Enabled = $true }
    Run        = @{
        Exit      = $true
        Container = $configRunContainer
    }
    Output     = @{ Verbosity = 'Detailed' }
}

# Invoke Pester without -PassThru and use the TestResult to capture results
Invoke-Pester -Configuration $config

# Capture results from the configuration
$results = $config.TestResult.Result

# Ensure results are captured
if ($results) {
    Write-Host "Test results captured successfully."
} else {
    Write-Host "No test results found!"
}

# Create data arrays for each test category
$sentinelConfiguration = $results | Where-Object { $_.Path -like "*SentinelConfiguration.Tests.ps1" } | ForEach-Object {
    [PSCustomObject]@{
        TestName = $_.Name
        Result = if ($_.Passed) { "Passed" } else { "Failed" }
        Time = "$($_.TimeTaken.TotalMilliseconds)ms"
        Error = if (-not $_.Passed) { $_.ResultMessage } else { $null }
    }
}

$workspaceConfiguration = $results | Where-Object { $_.Path -like "*WorkspaceConfiguration.Tests.ps1" } | ForEach-Object {
    [PSCustomObject]@{
        TestName = $_.Name
        Result = if ($_.Passed) { "Passed" } else { "Failed" }
        Time = "$($_.TimeTaken.TotalMilliseconds)ms"
        Error = if (-not $_.Passed) { $_.ResultMessage } else { $null }
    }
}

$dataConnectors = $results | Where-Object { $_.Path -like "*DataConnectors*.Tests.ps1" } | ForEach-Object {
    [PSCustomObject]@{
        TestName = $_.Name
        Result = if ($_.Passed) { "Passed" } else { "Failed" }
        Time = "$($_.TimeTaken.TotalMilliseconds)ms"
        Error = if (-not $_.Passed) { $_.ResultMessage } else { $null }
    }
}

# Check if data is available before exporting
if ($sentinelConfiguration.Count -gt 0) {
    Write-Host "Sentinel Configuration data available for export."
} else {
    Write-Host "No Sentinel Configuration data found."
}

if ($workspaceConfiguration.Count -gt 0) {
    Write-Host "Workspace Configuration data available for export."
} else {
    Write-Host "No Workspace Configuration data found."
}

if ($dataConnectors.Count -gt 0) {
    Write-Host "Data Connectors data available for export."
} else {
    Write-Host "No Data Connectors data found."
}

# Export the results to an Excel file
$excelFilePath = "C:\Users\peterp\OneDrive - BUI\Documents\mainstream_results.xlsx"

# Write to Excel, each test category on a different sheet
if ($sentinelConfiguration.Count -gt 0) {
    $sentinelConfiguration | Export-Excel -Path $excelFilePath -WorksheetName "Sentinel Configuration" -AutoSize
}
if ($workspaceConfiguration.Count -gt 0) {
    $workspaceConfiguration | Export-Excel -Path $excelFilePath -WorksheetName "Workspace Configuration" -AutoSize
}
if ($dataConnectors.Count -gt 0) {
    $dataConnectors | Export-Excel -Path $excelFilePath -WorksheetName "Data Connectors" -AutoSize
}

Write-Host "Results exported to $excelFilePath"
