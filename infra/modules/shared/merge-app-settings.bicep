//=============================================================================
// Merge App Settings in the Site Config
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the site for which to merge the app settings')
param siteName string

@secure()
@description('The current app settings of the site')
param currentAppSettings object 

@secure()
@description('The new app settings for the site')
param newAppSettings object

//=============================================================================
// Existing resources
//=============================================================================

resource site 'Microsoft.Web/sites@2024-04-01' existing = {
  name: siteName
}

//=============================================================================
// Resources
//=============================================================================

resource siteAppSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: site
  name: 'appsettings'
  properties: union(currentAppSettings, newAppSettings)
}
