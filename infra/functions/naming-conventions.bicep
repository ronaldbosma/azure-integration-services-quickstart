//=============================================================================
// Naming Conventions for Azure Resources
//=============================================================================

// Get resource name based on the convention: <resourceType>-<environment>-<region>-<instance>
// Functions based on: https://ronaldbosma.github.io/blog/2024/06/05/apply-azure-naming-convention-using-bicep-functions/
@export()
func getResourceName(resourceType string, environment string, region string, instance string) string => 
  shouldBeShortened(resourceType) 
    ? getShortenedResourceName(resourceType, environment, region, instance)
    : getResourceNameByConvention(resourceType, environment, region, instance)

func getResourceNameByConvention(resourceType string, environment string, region string, instance string) string => 
  sanitizeResourceName('${getPrefix(resourceType)}-${environment}-${abbreviateRegion(region)}-${instance}')


// Get the instance ID based on the provided instance name or generate a new one using the subscription, environment and location.
@export()
func getInstanceId(environment string, region string, instance string) string =>
  removeWhiteSpaces(instance) == '' ? generateInstanceId(environment, region) : instance

func generateInstanceId(environment string, region string) string =>
  substring(uniqueString(subscription().subscriptionId, environment, region), 0, 5)


//=============================================================================
// Shorten Names
//=============================================================================

func shouldBeShortened(resourceType string) bool => contains(getResourcesTypesToShorten(), resourceType)

// This is a list of resources that should be shortened.
func getResourcesTypesToShorten() array => [
  'keyVault'        // Has max length of 24
  'storageAccount'  // Has max length of 24 and only allows letters and numbers
  'virtualMachine'  // Has max length of 15 for Windows
]

func getShortenedResourceName(resourceType string, environment string, region string, instance string) string =>
  resourceType == 'virtualMachine'
    ? getVirtualMachineName(environment, region, instance)
    : shortenString(getResourceNameByConvention(resourceType, shortenEnvironmentName(environment), region, instance))

// Virtual machines have a max length of 15 characters so we use uniqueString to generate a short unique name
func getVirtualMachineName(environment string, region string, instance string) string =>
  'vm${substring(uniqueString(environment, region), 0, 13-length(shortenString(instance)))}${shortenString(instance)}'

// Shorten the environment name to max 12 characters.
func shortenEnvironmentName(value string) string => substring(shortenString(value), 0, min(12, length(shortenString(value))))

// Shorten the string by removing hyphens and sanitizing the resource name.
func shortenString(value string) string => removeHyphens(sanitizeResourceName(value))
func removeHyphens(value string) string => replace(value, '-', '')


//=============================================================================
// Sanitize
//=============================================================================

// Sanitize the resource name by removing illegal characters and converting it to lower case.
func sanitizeResourceName(value string) string => toLower(removeTrailingHyphen(removeColons(removeCommas(removeDots(removeSemicolons(removeUnderscores(removeWhiteSpaces(value))))))))

func removeTrailingHyphen(value string) string => endsWith(value, '-') ? substring(value, 0, max(0, length(value)-1)) : value
func removeColons(value string) string => replace(value, ':', '')
func removeCommas(value string) string => replace(value, ',', '')
func removeDots(value string) string => replace(value, '.', '')
func removeSemicolons(value string) string => replace(value, ';', '')
func removeUnderscores(value string) string => replace(value, '_', '')
func removeWhiteSpaces(value string) string => replace(value, ' ', '')


//=============================================================================
// Prefixes
//=============================================================================

func getPrefix(resourceType string) string => getPrefixMap()[resourceType]

// Prefixes for commonly used resources.
// Source for abbreviations: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
func getPrefixMap() object => {
  actionGroup: 'ag'
  alert: 'al'
  apiManagement: 'apim'
  appConfigurationStore: 'appcs'
  applicationGateway: 'agw'
  applicationInsights: 'appi'
  appServiceEnvironment: 'ase'
  appServicePlan: 'asp'
  containerApps: 'ca'
  containerAppsEnvironment: 'cae'
  containerInstance: 'ci'
  containerRegistry: 'cr'
  dashboard: 'dash'
  eventHub: 'evh'
  eventHubsNamespace: 'evhns'
  functionApp: 'func'
  keyVault: 'kv'
  loadBalancerInternal: 'lbi'
  loadBalancerExternal: 'lbe'
  loadBalancerRule: 'rule'
  logAnalyticsWorkspace: 'log'
  logAnalyticsQueryPack: 'pack'
  logicApp: 'logic'
  managedIdentity: 'id'
  networkInterface: 'nic'
  networkSecurityGroup: 'nsg'
  publicIpAddress: 'pip'
  redisCache: 'redis'
  resourceGroup: 'rg'
  serviceBusNamespace: 'sbns'
  serviceBusQueue: 'sbq'
  serviceBusTopic: 'sbt'
  serviceBusTopicSubscription: 'sbts'
  sqlDatabaseServer: 'sql'
  staticWebapp: 'stapp'
  storageAccount: 'st'
  subnet: 'snet'
  synapseWorkspace: 'syn'
  virtualMachine: 'vm'
  virtualNetwork: 'vnet'
  webApp: 'app' 
  
  // Custom prefixes not specified on the Microsoft site
  appRegistration: 'appreg'
  azdEnvironment: 'azd'
  client: 'client'
  webtest: 'webtest'
}


//=============================================================================
// Regions
//=============================================================================

func abbreviateRegion(region string) string => getRegionMap()[region]

// Map Azure region name to Short Name (CAF) abbreviation taken from: https://www.jlaundry.nz/2022/azure_region_abbreviations/
func getRegionMap() object => {
  australiacentral: 'acl'
  australiacentral2: 'acl2'
  australiaeast: 'ae'
  australiasoutheast: 'ase'
  brazilsouth: 'brs'
  brazilsoutheast: 'bse'
  canadacentral: 'cnc'
  canadaeast: 'cne'
  centralindia: 'inc'
  centralus: 'cus'
  centraluseuap: 'ccy'
  eastasia: 'ea'
  eastus: 'eus'
  eastus2: 'eus2'
  eastus2euap: 'ecy'
  francecentral: 'frc'
  francesouth: 'frs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  italynorth: 'itn'
  japaneast: 'jpe'
  japanwest: 'jpw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  northcentralus: 'ncus'
  northeurope: 'ne'
  norwayeast: 'nwe'
  norwaywest: 'nww'
  qatarcentral: 'qac'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scus'
  southindia: 'ins'
  southeastasia: 'sea'
  swedencentral: 'sdc'
  swedensouth: 'sds'
  switzerlandnorth: 'szn'
  switzerlandwest: 'szw'
  uaecentral: 'uac'
  uaenorth: 'uan'
  uksouth: 'uks'
  ukwest: 'ukw'
  westcentralus: 'wcus'
  westeurope: 'we'
  westindia: 'inw'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  chinaeast: 'sha'
  chinaeast2: 'sha2'
  chinanorth: 'bjb'
  chinanorth2: 'bjb2'
  chinanorth3: 'bjb3'
  germanycentral: 'gec'
  germanynortheast: 'gne'
  usdodcentral: 'udc'
  usdodeast: 'ude'
  usgovarizona: 'uga'
  usgoviowa: 'ugi'
  usgovtexas: 'ugt'
  usgovvirginia: 'ugv'
  usnateast: 'exe'
  usnatwest: 'exw'
  usseceast: 'rxe'
  ussecwest: 'rxw'
}
