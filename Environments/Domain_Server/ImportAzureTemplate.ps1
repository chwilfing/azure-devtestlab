#---------------------------------------------------------------------
# ImportAzureTemplate.ps1
# Deploy selected ARM template to Azure. 
# The user gets dialog boxes that ask for subscription and templates.
# atwork.at, Dec. 2018 by Christoph Wilfing
#---------------------------------------------------------------------
# $AzureCredential = Get-Credential -Message 'AzureAdmin' -UserName 'user@irgendwas.onmicrosoft.com'

if ($null -eq $AzureSubscription) {
    Add-AzureRmAccount | Out-Null
    $AzureSubscription = Get-AzureRMSubscription | Out-GridView -Title 'Select Azure Subscription' -OutputMode Single
}

Set-AzureRmContext -SubscriptionId $AzureSubscription.SubscriptionId

$DeploymentName = (New-Guid).Guid
if ($null -eq $AzureResourceGroupName) {
    $AzureResourceGroupName = Read-Host -Prompt 'Name of the resourcegroup to create / deploy'
}
$AzureLocation = 'North Europe'

New-AzureRmResourceGroup -Name $AzureResourceGroupName -Location $AzureLocation -Force

#Find templates in current directory
$Templates = Get-ChildItem -Path $PSScriptRoot -Recurse -File | Where-Object { ($_.Extension -eq '.json') -and ($_.Name -NotLike '*parameter*') }
if ($Templates -is [System.Array]) {
    $Template = $Templates | Out-GridView -Title 'Select Template' -OutputMode Single
}
else {
    $Template = $Templates
}

#Find Template Configs in current directory

$TemplateConfigs = Get-ChildItem -Path $PSScriptRoot -Recurse -File | Where-Object Name -like '*.parameter*.json'
if ($TemplateConfigs -is [System.Array]) {
    $TemplateConfig = $TemplateConfigs | `Out-GridView `
        -Title 'Select TemplateConfig' `
        -OutputMode Single
}
else {
    $TemplateConfig = $TemplateConfigs
}

do {
    $Key = Read-Host -Prompt '[T]est or [D]eploy'
} while ($key -ne 'T' -and $Key -ne 'D')

if ($key -eq 'D') {
    New-AzureRMResourceGroupDeployment `
        -Name $DeploymentName `
        -ResourceGroupName $AzureResourceGroupName `
        -TemplateFile $Template.FullName `
        -TemplateParameterFile $TemplateConfig.FullName `
        -Force `
        -Mode Incremental `
        -Verbose
}
elseif ($key -eq 'T')  {
    $Result = Test-AzureRmResourceGroupDeployment `
        -ResourceGroupName $AzureResourceGroupName `
        -Mode Incremental `
        -TemplateFile $Template.FullName `
        -TemplateParameterFile $TemplateConfig.FullName `
        -Verbose
    $result
}
