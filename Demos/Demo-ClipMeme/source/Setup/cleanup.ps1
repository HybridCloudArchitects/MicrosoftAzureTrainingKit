Param([string] $azureSettingsFile)

$scriptDir = (split-path $myinvocation.mycommand.path -parent)
Set-Location $scriptDir

$FunctionToRegister = Join-Path $scriptDir ".\Tasks\Invoke-AzureEnvironmentSetup.ps1"
. "$FunctionToRegister"

# Import progress functions
. ".\tasks\progress-functions.ps1"

# "========= Initialization =========" #
pushd ".."

# Import required settings from config.local.xml
[xml] $xmlAzureSettings = Get-Content $azureSettingsFile

# Local Paths

[string] $solutionWorkingDir = $xmlAzureSettings.configuration.localPaths.solutionWorkingDir
[string] $solutionsDir = $xmlAzureSettings.configuration.localPaths.solutionsDir
[string] $beginSolutionDir = Join-Path $scriptDir "$solutionsDir\Begin\ClipMeme"
[string] $beginSolutionDirSettings = "$beginSolutionDir\ClipMeme\web.config"
[string] $endSolutionDir = Join-Path $scriptDir "$solutionsDir\End\ClipMeme"
[string] $endSolutionDirSettings = "$endSolutionDir\ClipMeme\web.config"

# Client Settings
[string] $DisplayName = $xmlAzureSettings.configuration.clientSettings.DisplayName

# Windows Azure
[string] $EnvironmentSubscriptionName = $xmlAzureSettings.configuration.windowsAzureSubscription.EnvironmentSubscriptionName
[string] $EnvironmentPrimaryLocation = $xmlAzureSettings.configuration.windowsAzureSubscription.EnvironmentPrimaryLocation
[string] $StorageAccountName = $xmlAzureSettings.configuration.windowsAzureSubscription.StorageAccountName
[string] $WebsiteName = $xmlAzureSettings.configuration.windowsAzureSubscription.WebsiteName
$TrafficManagerProfile = $xmlAzureSettings.configuration.windowsAzureSubscription.TrafficManagerProfile
$PublishSettingsFile = Join-Path $scriptDir ".\assets\publishSettings\azure.publishsettings"
$StorageContainers = @('uploads','memes')
$EnvironmentWebSites = @{$WebsiteName=$EnvironmentPrimaryLocation}
$EnvironmentStagingSites = @{$WebsiteName=$EnvironmentPrimaryLocation}
$WebsiteUrl = "http://$WebsiteName.azurewebsites.net"

$AppSettings = @{'DisplayName'=$DisplayName; 'TrafficManagerRegion'=$EnvironmentPrimaryLocation; 'Website'=$WebsiteUrl}

popd

Invoke-AzureEnvironmentSetup -EnvironmentSubscriptionName $EnvironmentSubscriptionName `
                             -EnvironmentPrimaryLocation $EnvironmentPrimaryLocation `
                             -StorageEnvironmentLocation $EnvironmentPrimaryLocation `
                             -EnvironmentWebSites $EnvironmentWebSites `
                             -EnvironmentStagingSites $EnvironmentStagingSites `
                             -EnvironmentStorageAccount $StorageAccountName `
                             -StorageContainers $StorageContainers `
							 -AppSettings $AppSettings `
							 -TrafficManagerProfile $TrafficManagerProfile `
							 -beginSolutionDirSettings $beginSolutionDirSettings `
							 -endSolutionDirSettings $endSolutionDirSettings `
							 -PublishSettingsFile $PublishSettingsFile

Write-Action "Removing current working directory..."
if (Test-Path "$solutionWorkingDir")
{
	Remove-Item "$solutionWorkingDir" -recurse -force
}
Write-Done

Write-Action "Creating working directory..."
New-Item "$solutionWorkingDir" -type directory | Out-Null
if (!(Test-Path "$solutionWorkingDir"))
{
	New-Item "$solutionWorkingDir" -type directory | Out-Null
}
Copy-Item "$beginSolutionDir\*" "$solutionWorkingDir" -Recurse -Force

Copy-Item "$scriptDir\assets\demogif\demo.gif" "$solutionWorkingDir\..\" -Force

Write-Done