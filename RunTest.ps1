#region Install required modules
if ( -not ( Get-Module -ListAvailable Az.Accounts ) ) { 
    Install-Module Az.Accounts -Force -AllowClobber
}
#endregion

$workspaceName = "LAW-SecOps-Prod"
$resourceGroup = "rg-secops-prod"
$subscriptionId = "d680033d-8a87-4484-836a-99668acd3b09"

$configRunContainer = New-PesterContainer -Path "*.Tests.ps1" -Data @{
    # Define your environment variables here
    workspaceName  = $workspaceName
    resourceGroup  = $resourceGroup
    subscriptionId = $subscriptionId
}

Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

$config = New-PesterConfiguration -Hashtable @{
    Filter     = @{
        # Use the filter configuration to only specify the tests
        # This way you can easily remove e.g. specific dataconnectors from the test without mofiying the test itself
        # You will always have to modify the tests.ps1 file if you would like to remove specific tables it change the target configuration
        Tag = "Configuration", "AnalyticsRules", "Watchlists", "AAD", "AADIPC", "AzureActivity", "DfC", "O365"
    }
    TestResult = @{ Enabled = $true }
    Run        = @{
        Exit      = $true
        Container = $configRunContainer
    }
    Output     = @{ Verbosity = 'Detailed' }
}
Invoke-Pester -Configuration $config
