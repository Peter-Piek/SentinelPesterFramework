param (
    [Parameter(Mandatory = $true)]
    [string]$workspaceName,

    [Parameter(Mandatory = $true)]
    [string]$resourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$CICDPathRoot
)

BeforeDiscovery {
    # Define the Analytics rule ids that should be present and enabled
    $AnalyticsRuleIds = @(
        "BuiltInFusion",
        "4f7e9626-cb71-472d-a16a-18506453b00c",
        "0edb2b4b-c151-41ff-9815-90fd9835427d",
        "c32afea6-34fe-418d-9d5f-66d737d54c08",
        "e97e43f3-5be7-4487-b655-dac4e10d982d",
        "ba46204e-0ebe-404c-8c31-995ba81c96d1",
        "44a7cf22-9451-4ffc-9e98-ce1031c3ca3b",
        "49bd1f7b-fc7b-4a57-ba94-f57183572afc",
        "40702da1-ae8a-4e46-ac1f-9327ca6ef588",
        "df3c57be-3378-4f5e-a9de-72fdf62e5044"
    )
}


BeforeAll {
    # More information about the API can be found here:
    # https://learn.microsoft.com/en-us/rest/api/securityinsights/stable/alert-rules/list?tabs=HTTP
    # Query Analytics rules
    $RestUri = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}/providers/Microsoft.SecurityInsights/alertRules?api-version=2022-11-01" -f $subscriptionId, $resourceGroup, $workspaceName
    $CurrentItems = Invoke-AzRestMethod -Method GET -Uri $RestUri | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty value
}

Describe "Analytics Rules" -Tag "AnalyticsRules" {

    It "Analytics rules should not be in state `"AUTO DISABLED`"" {
        # https://learn.microsoft.com/en-us/azure/sentinel/detect-threats-custom#issue-a-scheduled-rule-failed-to-execute-or-appears-with-auto-disabled-added-to-the-name
        $CurrentItems | Where-Object { $_.properties.displayName -match "AUTO DISABLED" } | Should -BeNullOrEmpty
    }

    It "Analytics rule <_> is present" -ForEach @( $AnalyticsRuleIds ) {
        $AnalyticsRuleId = $_
        $AnalyticsRule = $CurrentItems | Where-Object { $_.id -match $AnalyticsRuleId }
        $AnalyticsRule.id | Should -Match $AnalyticsRuleId
    }

    It "Analytics rule <_> is enabled" -ForEach @( $AnalyticsRuleIds ) {
        $AnalyticsRuleId = $_
        $AnalyticsRule = $CurrentItems | Where-Object { $_.id -match $AnalyticsRuleId }
        $AnalyticsRule.properties.enabled | Should -Be $true
    }
}